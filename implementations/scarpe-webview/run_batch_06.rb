#!/usr/bin/env ruby
# Run batch 06 tests and output results

require_relative "scarpe_webview_runner"
include Scarpe::Webview::Runner

batch_file = File.expand_path("../../batches/batch_06.txt", __dir__)
test_paths = File.readlines(batch_file).map(&:strip).reject(&:empty?)

results = []

test_paths.each do |rel_path|
  test_path = File.join("../../", rel_path)
  
  unless File.exist?(test_path)
    results << { path: rel_path, status: "NOT_FOUND" }
    next
  end
  
  content = File.read(test_path)
  parts = content.split(/^-{3,}\s*(app code|test code)\s*$/)
  app_code = parts[2]&.strip || ""
  test_code = parts[4]&.strip || ""
  
  metadata = {
    "category" => File.dirname(rel_path).gsub("-", "_"),
    "test_name" => File.basename(rel_path).gsub("-", "_")
  }
  
  begin
    result_file = run_scarpe_command_line_test(metadata, app_code, test_code, env: {"SCARPE_HTML_RENDERER" => "calzini"})
    
    if result_file && File.exist?(result_file)
      json = JSON.parse(File.read(result_file))
      test_result = json.first
      
      if test_result["failures"].empty?
        results << { path: rel_path, status: "PASS", assertions: test_result["assertions"] }
      elsif test_result["failures"].any? { |f| f[1]&.include?("Minitest::Skip") }
        results << { path: rel_path, status: "SKIP" }
      else
        results << { path: rel_path, status: "FAIL", error: "assertion failure" }
      end
    else
      results << { path: rel_path, status: "ERROR", error: "no result file" }
    end
  rescue => e
    results << { path: rel_path, status: "ERROR", error: e.message[0..100] }
  end
end

# Output summary
puts "\n=== BATCH 06 RESULTS ==="
pass = results.count { |r| r[:status] == "PASS" }
skip = results.count { |r| r[:status] == "SKIP" }
fail_count = results.count { |r| r[:status] == "FAIL" }
error = results.count { |r| r[:status] == "ERROR" || r[:status] == "NOT_FOUND" }

puts "PASS: #{pass} | SKIP: #{skip} | FAIL: #{fail_count} | ERROR: #{error}"
puts ""

results.each do |r|
  status_icon = case r[:status]
    when "PASS" then "✅"
    when "SKIP" then "⏭️"
    when "FAIL" then "❌"
    else "⚠️"
  end
  puts "#{status_icon} #{r[:path]} - #{r[:status]}"
  puts "   #{r[:error]}" if r[:error]
end
