require_relative "scarpe_webview_runner"
include Scarpe::Webview::Runner

test_path = ARGV[0] || "../../cases/drawables/para/para_replace.sspec"
content = File.read(test_path)

parts = content.split(/^-{3,}\s*(app code|test code)\s*$/)
app_code = parts[2]&.strip || ""
test_code = parts[4]&.strip || ""

metadata = {
  "category" => File.dirname(test_path).sub("../../cases/", ""),
  "test_name" => File.basename(test_path)
}

puts "=== Running: #{test_path} ==="
result = run_scarpe_command_line_test(metadata, app_code, test_code, env: {"SCARPE_HTML_RENDERER" => "calzini"})
if result && File.exist?(result)
  puts "Result file contents:"
  puts File.read(result)
else
  puts "ERROR or no result"
end
