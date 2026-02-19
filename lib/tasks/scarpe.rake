# frozen_string_literal: true

require "json"
require "yaml"
require "fileutils"
require "rbconfig"
require "timeout"
require "tempfile"

namespace :scarpe do
  ROOT_DIR = File.expand_path("../..", __dir__)
  CASES_DIR = File.join(ROOT_DIR, "cases")
  RESULTS_DIR = File.join(ROOT_DIR, "results", "scarpe-suite")
  RESULTS_FILE = File.join(RESULTS_DIR, "results.json")
  IMPL_DIR = File.join(ROOT_DIR, "implementations", "scarpe-webview")

  desc "Run all shoes-spec tests for Scarpe"
  task :all do
    ScarpeRunner.run_all
  end

  desc "Show summary of last run (without re-running)"
  task :summary do
    ScarpeRunner.show_summary
  end

  desc "Run only failing specs from last run"
  task :failing do
    ScarpeRunner.run_failing
  end

  desc "Run a specific category (e.g., rake scarpe:category[drawables/button])"
  task :category, [:name] do |t, args|
    ScarpeRunner.run_category(args[:name])
  end

  desc "List all categories"
  task :categories do
    ScarpeRunner.list_categories
  end

  module ScarpeRunner
    extend self

    def run_all
      FileUtils.mkdir_p(RESULTS_DIR)
      
      specs = collect_all_specs
      puts "\n#{"=" * 60}"
      puts "shoes-spec Suite for Scarpe"
      puts "=" * 60
      puts "Running #{specs.length} specs...\n\n"

      start_time = Time.now
      results = run_specs(specs)
      elapsed = Time.now - start_time

      save_results(results, elapsed)
      print_summary(results, elapsed)
    end

    def run_failing
      unless File.exist?(RESULTS_FILE)
        puts "No previous results found. Run `rake scarpe:all` first."
        exit 1
      end

      data = JSON.parse(File.read(RESULTS_FILE))
      failing_paths = data["specs"].select { |s| s["status"] == "fail" || s["status"] == "error" }
                                    .map { |s| s["path"] }

      if failing_paths.empty?
        puts "No failing specs to re-run! 🎉"
        exit 0
      end

      puts "\n#{"=" * 60}"
      puts "Re-running #{failing_paths.length} failing specs"
      puts "=" * 60

      specs = failing_paths.map do |p|
        { file: p, test_name: File.basename(p, ".sspec"), category: extract_category(p) }
      end
      
      start_time = Time.now
      results = run_specs(specs)
      elapsed = Time.now - start_time

      # Merge with previous results
      previous = data["specs"].reject { |s| failing_paths.include?(s["path"]) }
      merged = previous + results
      save_results(merged, elapsed)
      print_summary(results, elapsed, label: "Re-run Results")
    end

    def run_category(category_name)
      unless category_name
        puts "Usage: rake scarpe:category[drawables/button]"
        puts "\nRun `rake scarpe:categories` to see available categories."
        exit 1
      end

      specs = collect_all_specs.select { |s| s[:category] == category_name }
      
      if specs.empty?
        puts "No specs found for category: #{category_name}"
        exit 1
      end

      puts "\n#{"=" * 60}"
      puts "Running #{specs.length} specs in #{category_name}"
      puts "=" * 60

      start_time = Time.now
      results = run_specs(specs)
      elapsed = Time.now - start_time

      print_summary(results, elapsed, label: "Category: #{category_name}")
    end

    def list_categories
      categories = discover_categories
      puts "\nAvailable categories (#{categories.length}):"
      
      # Group by top-level for cleaner display
      by_top = categories.group_by { |c| c.split("/").first }
      by_top.keys.sort.each do |top|
        cats = by_top[top]
        if cats.length == 1 && cats.first == top
          count = Dir.glob("#{CASES_DIR}/#{top}/*.sspec").length
          puts "  #{top}/ (#{count} specs)"
        else
          total = cats.sum { |c| Dir.glob("#{CASES_DIR}/#{c}/*.sspec").length }
          puts "  #{top}/ (#{total} specs total)"
          cats.sort.each do |cat|
            next if cat == top
            count = Dir.glob("#{CASES_DIR}/#{cat}/*.sspec").length
            next if count == 0
            indent = cat.sub(top + "/", "")
            puts "    └── #{indent} (#{count})"
          end
        end
      end
    end

    def show_summary
      unless File.exist?(RESULTS_FILE)
        puts "No results found. Run `rake scarpe:all` first."
        exit 1
      end

      data = JSON.parse(File.read(RESULTS_FILE))
      results = data["specs"]
      elapsed = data["elapsed_seconds"]
      timestamp = data["timestamp"]

      puts "\n#{"=" * 60}"
      puts "shoes-spec Suite Results"
      puts "Last run: #{timestamp}"
      puts "=" * 60
      print_stats(results, elapsed)
      print_failure_reasons(results)
    end

    private

    def discover_categories
      # Find all directories that contain .sspec files (any depth)
      all_sspec_files = Dir.glob("**/*.sspec", base: CASES_DIR)
      categories = all_sspec_files.map { |f| File.dirname(f) }.uniq.sort
      categories
    end

    def collect_all_specs
      specs = []
      # Find all .sspec files recursively
      Dir.glob("#{CASES_DIR}/**/*.sspec").each do |sspec_file|
        rel_path = sspec_file.sub("#{CASES_DIR}/", "")
        specs << {
          file: sspec_file,
          test_name: File.basename(sspec_file, ".sspec"),
          category: File.dirname(rel_path)
        }
      end
      specs.sort_by { |s| [s[:category], s[:test_name]] }
    end

    def extract_category(path)
      # Extract category from path like .../cases/drawables/button/foo.sspec
      path.sub(/.*\/cases\//, "").sub(/\/[^\/]+\.sspec$/, "")
    end

    def run_specs(specs)
      results = []
      total = specs.length
      
      specs.each_with_index do |spec, idx|
        progress = "[#{(idx + 1).to_s.rjust(total.to_s.length)}/#{total}]"
        
        result = run_single_spec(spec)
        results << result

        # Print quick status
        status_char = case result["status"]
                      when "pass" then "\e[32m.\e[0m"
                      when "skip" then "\e[33mS\e[0m"
                      when "fail" then "\e[31mF\e[0m"
                      when "error" then "\e[31mE\e[0m"
                      end
        short_name = "#{spec[:category]}/#{spec[:test_name]}"
        short_name = short_name[0..58] + "..." if short_name.length > 60
        puts "#{progress} #{status_char} #{short_name}"
      end

      results
    end

    def run_single_spec(spec)
      result = {
        "name" => spec[:test_name],
        "category" => spec[:category],
        "path" => spec[:file],
        "status" => "error",
        "failures" => [],
        "error_message" => nil
      }

      begin
        # Read and parse the spec file
        content = File.read(spec[:file], encoding: "UTF-8", invalid: :replace, undef: :replace)
        parts = content.split(/^-{3,}\s*(app code|test code)\s*$/i)
        
        if parts.length < 5
          result["status"] = "error"
          result["error_message"] = "Invalid sspec format"
          return result
        end

        app_code = parts[2]&.strip || ""
        test_code = parts[4]&.strip || ""

        # Check for explicit skip in test code
        if test_code =~ /^\s*skip\s+["'](.+?)["']/
          result["status"] = "skip"
          result["error_message"] = $1
          return result
        end

        # Run the spec using scarpe-webview implementation
        sspec_file = run_scarpe_test(spec, app_code, test_code)
        
        if sspec_file.nil? || !File.exist?(sspec_file.to_s)
          result["status"] = "error"
          result["error_message"] = "No result file produced"
          return result
        end

        # Parse the minitest result
        parse_minitest_result(sspec_file, result)

      rescue => e
        result["status"] = "error"
        result["error_message"] = "#{e.class}: #{e.message}"
      end

      result
    end

    def run_scarpe_test(spec, app_code, test_code)
      # Use the scarpe-webview implementation's run_single.rb approach
      sspec_output = File.join(IMPL_DIR, "sspec.json")
      
      # Clean up previous result
      File.unlink(sspec_output) if File.exist?(sspec_output)

      app_file = Tempfile.new(["shoes-spec-app", ".rb"])
      app_file.write(app_code)
      app_file.close

      test_file = Tempfile.new(["shoes-spec-test", ".rb"])
      test_file.write(test_code)
      test_file.close

      # Build the environment
      env = {
        "SHOES_SPEC_TEST" => test_file.path,
        "SCARPE_DISPLAY_SERVICE" => "wv_local",
        "SCARPE_HTML_RENDERER" => "calzini",
        "SHOES_MINITEST_EXPORT_FILE" => sspec_output,
        "SHOES_MINITEST_CLASS_NAME" => spec[:category].gsub("/", "_").gsub("-", "_"),
        "SHOES_MINITEST_METHOD_NAME" => spec[:test_name].gsub("-", "_")
      }

      # Use bundle exec scarpe from scarpe-webview implementation
      Dir.chdir(IMPL_DIR) do
        Bundler.with_unbundled_env do
          pid = spawn(env, "bundle", "exec", "scarpe", "--dev", app_file.path,
                      [:out, :err] => "/dev/null")
          
          # Wait with timeout (30 seconds)
          begin
            Timeout.timeout(30) { Process.wait(pid) }
          rescue Timeout::Error
            Process.kill("TERM", pid) rescue nil
            Process.wait(pid) rescue nil
            app_file.unlink rescue nil
            test_file.unlink rescue nil
            return nil
          end
        end
      end
      
      app_file.unlink rescue nil
      test_file.unlink rescue nil

      File.exist?(sspec_output) ? sspec_output : nil
    end

    def parse_minitest_result(file, result)
      data = JSON.parse(File.read(file))
      entry = data.is_a?(Array) ? data.first : data

      unless entry
        result["status"] = "error"
        result["error_message"] = "Empty result file"
        return
      end

      failures = entry["failures"] || []
      
      if failures.empty?
        result["status"] = "pass"
      else
        failure_type, failure_data = failures.first
        
        if failure_type == "exception"
          begin
            parsed = JSON.parse(failure_data)
            if parsed["json_class"]&.include?("Skip")
              result["status"] = "skip"
              result["error_message"] = parsed["m"]
            else
              result["status"] = "fail"
              result["error_message"] = parsed["m"] || failure_data
            end
          rescue
            result["status"] = "fail"
            result["error_message"] = failure_data.to_s[0..200]
          end
        else
          result["status"] = "fail"
          result["error_message"] = failure_data.to_s[0..200]
        end
        
        result["failures"] = failures.map { |f| f.first }
      end
    end

    def save_results(results, elapsed)
      data = {
        "timestamp" => Time.now.strftime("%Y-%m-%d %H:%M:%S"),
        "elapsed_seconds" => elapsed.round(2),
        "total" => results.length,
        "specs" => results
      }

      FileUtils.mkdir_p(RESULTS_DIR)
      File.write(RESULTS_FILE, JSON.pretty_generate(data))
    end

    def print_summary(results, elapsed, label: "Suite Results")
      puts "\n\n#{"=" * 60}"
      puts "shoes-spec #{label}"
      puts "=" * 60
      print_stats(results, elapsed)
      print_failure_reasons(results)
    end

    def print_stats(results, elapsed)
      total = results.length
      passed = results.count { |r| r["status"] == "pass" }
      failed = results.count { |r| r["status"] == "fail" }
      skipped = results.count { |r| r["status"] == "skip" }
      errors = results.count { |r| r["status"] == "error" }

      pass_pct = total > 0 ? (passed.to_f / total * 100).round(1) : 0
      fail_pct = total > 0 ? (failed.to_f / total * 100).round(1) : 0
      skip_pct = total > 0 ? (skipped.to_f / total * 100).round(1) : 0
      err_pct = total > 0 ? (errors.to_f / total * 100).round(1) : 0

      puts ""
      puts "Total:   #{total.to_s.rjust(6)}"
      puts "Passed:  #{passed.to_s.rjust(6)} (#{pass_pct}%) \e[32m#{"█" * (pass_pct / 5).to_i}\e[0m"
      puts "Failed:  #{failed.to_s.rjust(6)} (#{fail_pct}%) \e[31m#{"█" * (fail_pct / 5).to_i}\e[0m"
      puts "Skipped: #{skipped.to_s.rjust(6)} (#{skip_pct}%) \e[33m#{"█" * (skip_pct / 5).to_i}\e[0m"
      puts "Errors:  #{errors.to_s.rjust(6)} (#{err_pct}%) \e[31m#{"█" * (err_pct / 5).to_i}\e[0m"
      puts ""
      puts "Time: #{format_time(elapsed)}"
    end

    def format_time(seconds)
      if seconds < 60
        "#{seconds.round(1)}s"
      elsif seconds < 3600
        mins = (seconds / 60).to_i
        secs = (seconds % 60).round(0)
        "#{mins}m #{secs}s"
      else
        hours = (seconds / 3600).to_i
        mins = ((seconds % 3600) / 60).to_i
        "#{hours}h #{mins}m"
      end
    end

    def print_failure_reasons(results)
      # Group failures by error message
      failure_messages = Hash.new(0)
      
      results.select { |r| r["status"] == "fail" || r["status"] == "error" }
             .each do |r|
        msg = r["error_message"] || "Unknown error"
        # Normalize the message for grouping
        normalized = normalize_error(msg)
        failure_messages[normalized] += 1
      end

      return if failure_messages.empty?

      puts "\n" + "-" * 60
      puts "Top 10 Failure Reasons:"
      puts "-" * 60
      
      failure_messages.sort_by { |_, count| -count }
                      .first(10)
                      .each_with_index do |(msg, count), idx|
        # Truncate long messages
        display_msg = msg.length > 50 ? msg[0..47] + "..." : msg
        puts "#{(idx + 1).to_s.rjust(2)}. #{display_msg} - #{count} specs"
      end
    end

    def normalize_error(msg)
      return "Unknown error" if msg.nil? || msg.empty?
      
      # Group similar errors together
      case msg
      when /NoMethodError.*undefined method.*buttons/i
        "NoMethodError: buttons() not defined"
      when /NoMethodError.*undefined method.*paras/i
        "NoMethodError: paras() not defined"
      when /NoMethodError.*undefined method.*'(\w+)'/
        "NoMethodError: #{$1}() not defined"
      when /TODO:/
        msg.split("\n").first[0..60]
      when /Invalid sspec format/
        "Invalid sspec format"
      when /No result file/
        "No result file produced (crash/timeout)"
      when /Expected.*to equal/i
        "Assertion failed: expected vs actual mismatch"
      when /NameError.*uninitialized constant/
        match = msg.match(/uninitialized constant (\S+)/)
        match ? "NameError: #{match[1]}" : "NameError: uninitialized constant"
      else
        msg.split("\n").first.gsub(/\s+/, " ").strip[0..55]
      end
    end
  end
end
