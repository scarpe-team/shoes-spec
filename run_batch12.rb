# Run batch 12 tests
require "bundler/setup"
require "rbconfig"
require "json"
require "scarpe/components/file_helpers"
require "scarpe/components/minitest_result"
require "scarpe/components/segmented_file_loader"

include Scarpe::Components::FileHelpers

BATCH_FILE = File.join(__dir__, "batches/batch_12.txt")
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
    sspec_file = File.join(__dir__, "implementations/niente/sspec_batch12.json")
    
    ENV["SHOES_SPEC_TEST"] = test_file
    ENV["SCARPE_DISPLAY_SERVICE"] = "niente"
    ENV["SHOES_MINITEST_EXPORT_FILE"] = sspec_file
    ENV["SHOES_MINITEST_CLASS_NAME"] = "Batch12"
    ENV["SHOES_MINITEST_METHOD_NAME"] = test_name
    
    result = system(RbConfig.ruby, `which scarpe`.strip, "--dev", app_file, err: "/dev/null", out: "/dev/null")
    
    if result && File.exist?(sspec_file)
      json = JSON.parse(File.read(sspec_file))
      status = if json[0]["failures"].empty?
        :pass
      elsif json[0]["failures"].any? { |f| f[0] == "skip" }
        :skip
      else
        :fail
      end
      {name: test_name, status: status, failures: json[0]["failures"].map { |f| f[0] }, assertions: json[0]["assertions"]}
    else
      {name: test_name, status: :error, failures: ["failed to run"], assertions: 0}
    end
  end
end

puts "Running batch 12 tests..."

File.readlines(BATCH_FILE).each do |line|
  line = line.strip
  next if line.empty?
  
  sspec_path = File.join(CASES_DIR, line.sub("cases/scarpe_examples/", ""))
  if File.exist?(sspec_path)
    puts "Testing: #{File.basename(sspec_path)}"
    result = run_test(sspec_path)
    RESULTS << result
    puts "  => #{result[:status]}"
  else
    puts "MISSING: #{sspec_path}"
    RESULTS << {name: File.basename(line), status: :missing, failures: [], assertions: 0}
  end
end

puts "\n=== SUMMARY ==="
pass = RESULTS.count { |r| r[:status] == :pass }
fail_count = RESULTS.count { |r| r[:status] == :fail }
skip = RESULTS.count { |r| r[:status] == :skip }
error = RESULTS.count { |r| r[:status] == :error }

puts "PASS: #{pass}"
puts "FAIL: #{fail_count}"
puts "SKIP: #{skip}"
puts "ERROR: #{error}"

puts "\n=== FAILURES ===" if fail_count > 0
RESULTS.select { |r| r[:status] == :fail }.each do |r|
  puts "#{r[:name]}: #{r[:failures].join(', ')}"
end

puts "\n=== ERRORS ===" if error > 0
RESULTS.select { |r| r[:status] == :error }.each do |r|
  puts "#{r[:name]}: #{r[:failures].join(', ')}"
end

# Export results for logging
File.write(File.join(__dir__, "results/batch12_results.json"), JSON.pretty_generate(RESULTS))
