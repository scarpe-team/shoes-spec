# Run batch 11 tests (Shoes 3-only features)
require "bundler/setup"
require "rbconfig"
require "json"
require "scarpe/components/file_helpers"
require "scarpe/components/minitest_result"
require "scarpe/components/segmented_file_loader"

include Scarpe::Components::FileHelpers

BATCH_FILE = File.join(__dir__, "batches/batch_11.txt")
CASES_DIR = File.join(__dir__, "cases/scarpe_examples")
RESULTS = []

def run_test(sspec_path)
  contents = File.read(sspec_path, encoding: "UTF-8")
  front_matter, segmap = Scarpe::Components::SegmentedFileLoader.front_matter_and_segments_from_file(contents)
  app_code = segmap.values[0]
  test_code = segmap.values[1]
  test_name = File.basename(sspec_path, ".sspec")
  
  with_tempfiles([
    ["app", app_code],
    ["test", test_code],
  ]) do |app_file, test_file|
    sspec_file = File.join(__dir__, "implementations/niente/sspec_batch11.json")
    
    ENV["SHOES_SPEC_TEST"] = test_file
    ENV["SCARPE_DISPLAY_SERVICE"] = "niente"
    ENV["SHOES_MINITEST_EXPORT_FILE"] = sspec_file
    ENV["SHOES_MINITEST_CLASS_NAME"] = "Batch11"
    ENV["SHOES_MINITEST_METHOD_NAME"] = test_name
    
    result = system(RbConfig.ruby, `which scarpe`.strip, "--dev", app_file, err: "/dev/null", out: "/dev/null")
    
    if result && File.exist?(sspec_file)
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
      {name: test_name, status: :error, failures: ["failed to run"], path: sspec_path}
    end
  end
end

puts "Running batch 11 tests (Shoes 3-only features)..."
puts "=" * 60

File.readlines(BATCH_FILE).each do |line|
  line = line.strip
  next if line.empty?
  
  sspec_path = File.join(CASES_DIR, line.sub("cases/scarpe_examples/", ""))
  if File.exist?(sspec_path)
    print "Testing: #{File.basename(sspec_path).ljust(30)}"
    result = run_test(sspec_path)
    RESULTS << result
    puts " => #{result[:status].to_s.upcase}"
  else
    puts "MISSING: #{sspec_path}"
    RESULTS << {name: File.basename(line), status: :missing, failures: [], path: sspec_path}
  end
end

puts "\n" + "=" * 60
puts "BATCH 11 SUMMARY"
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
results_json = File.join(__dir__, "implementations/niente/batch_11_results.json")
File.write(results_json, JSON.pretty_generate(RESULTS))
puts "\nResults written to: #{results_json}"
