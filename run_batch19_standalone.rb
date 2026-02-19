#!/usr/bin/env ruby
# Run batch 19 tests - Standalone version
# Run from any directory, doesn't require bundler

require "rbconfig"
require "json"
require "tempfile"
require "fileutils"

SHOES_SPEC_DIR = File.expand_path("~/Progrumms/shoes-spec")
BATCH_FILE = File.join(SHOES_SPEC_DIR, "batches/batch_19.txt")
CASES_DIR = File.join(SHOES_SPEC_DIR, "cases/scarpe_examples")
RESULTS = []
SCARPE_DIR = File.expand_path("~/Progrumms/scarpe")

def parse_sspec(contents)
  # Simple parser for .sspec format
  # Format: YAML front matter, then "----------- app code", then "----------- test code"
  
  parts = contents.split(/^-{3,}\s*(?:app code|test code)\s*$/i)
  
  if parts.length >= 3
    front_matter = parts[0]
    app_code = parts[1].strip
    test_code = parts[2].strip
    [app_code, test_code]
  else
    raise "Invalid sspec format: expected app code and test code sections"
  end
end

def run_test(sspec_path)
  contents = File.read(sspec_path, encoding: "UTF-8")
  app_code, test_code = parse_sspec(contents)
  test_name = File.basename(sspec_path, ".sspec")
  
  # Create temp files
  app_file = Tempfile.new(['app', '.rb'])
  test_file = Tempfile.new(['test', '.rb'])
  
  begin
    app_file.write(app_code)
    app_file.close
    
    test_file.write(test_code)
    test_file.close
    
    sspec_file = File.join(SHOES_SPEC_DIR, "implementations/niente/sspec_batch19.json")
    FileUtils.rm_f(sspec_file)
    
    env = {
      "SHOES_SPEC_TEST" => test_file.path,
      "SCARPE_DISPLAY_SERVICE" => "niente",
      "SHOES_MINITEST_EXPORT_FILE" => sspec_file,
      "SHOES_MINITEST_CLASS_NAME" => "Batch19",
      "SHOES_MINITEST_METHOD_NAME" => test_name
    }
    
    # Run scarpe from the scarpe directory using bundle exec
    result = Dir.chdir(SCARPE_DIR) do
      system(
        env,
        "bundle", "exec", "scarpe", "--dev", app_file.path,
        [:out, :err] => "/dev/null"
      )
    end
    
    if File.exist?(sspec_file)
      json = JSON.parse(File.read(sspec_file))
      first_failure = json[0]["failures"].first
      status = if json[0]["failures"].empty?
        :pass
      elsif first_failure && first_failure[0] == "pending_implementation"
        :pending
      elsif first_failure && first_failure[0] == "skip"
        :skip
      else
        :fail
      end
      {name: test_name, status: status, failures: json[0]["failures"].map { |f| f[0] }, path: sspec_path}
    else
      {name: test_name, status: :error, failures: ["no result file"], path: sspec_path}
    end
  rescue => e
    {name: test_name, status: :error, failures: [e.message], path: sspec_path}
  ensure
    app_file.unlink
    test_file.unlink
  end
end

puts "Running batch 19 tests..."
puts "=" * 60

File.readlines(BATCH_FILE).each do |line|
  line = line.strip
  next if line.empty?
  
  sspec_path = File.join(CASES_DIR, line.sub("cases/scarpe_examples/", ""))
  if File.exist?(sspec_path)
    print "Testing: #{File.basename(sspec_path).ljust(35)}"
    result = run_test(sspec_path)
    RESULTS << result
    puts " => #{result[:status].to_s.upcase}"
  else
    puts "MISSING: #{sspec_path}"
    RESULTS << {name: File.basename(line), status: :missing, failures: [], path: sspec_path}
  end
end

puts "\n" + "=" * 60
puts "BATCH 19 SUMMARY"
puts "=" * 60

pass = RESULTS.count { |r| r[:status] == :pass }
fail_count = RESULTS.count { |r| r[:status] == :fail }
pending = RESULTS.count { |r| r[:status] == :pending }
skip = RESULTS.count { |r| r[:status] == :skip }
error = RESULTS.count { |r| r[:status] == :error }
missing = RESULTS.count { |r| r[:status] == :missing }

puts "PASS:    #{pass}"
puts "PENDING: #{pending}"
puts "FAIL:    #{fail_count}"
puts "SKIP:    #{skip}"
puts "ERROR:   #{error}"
puts "MISSING: #{missing}"
puts "-" * 60
puts "TOTAL:   #{RESULTS.length}"

if fail_count > 0
  puts "\n=== FAILURES ==="
  RESULTS.select { |r| r[:status] == :fail }.each do |r|
    puts "#{r[:name]}: #{r[:failures].join(', ')}"
  end
end

if error > 0
  puts "\n=== ERRORS ==="
  RESULTS.select { |r| r[:status] == :error }.each do |r|
    puts "#{r[:name]}: #{r[:failures].join(', ')}"
  end
end

# Write JSON results
results_json = File.join(SHOES_SPEC_DIR, "implementations/niente/batch_19_results.json")
File.write(results_json, JSON.pretty_generate(RESULTS))
puts "\nResults written to: #{results_json}"

# Generate markdown table for session log
puts "\n" + "=" * 60
puts "MARKDOWN TABLE"
puts "=" * 60
puts "| Test | Status |"
puts "|------|--------|"
RESULTS.each do |r|
  emoji = case r[:status]
  when :pass then "✅"
  when :fail then "❌"
  when :skip then "⏭️"
  when :pending then "⏳"
  when :error then "💥"
  else "❓"
  end
  puts "| #{r[:name]} | #{emoji} #{r[:status]} |"
end
