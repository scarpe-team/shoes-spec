# frozen_string_literal: true

require_relative "lib/shoes-spec/report_results"
require "fileutils"

# Load custom rake tasks
Dir.glob("lib/tasks/**/*.rake").each { |r| load r }

include ShoesSpec

def compare_all_results
  passed = true
  passed &= compare_results(display: "scarpe-webview", config: "local-calzini")
  passed &= compare_results(display: "scarpe-webview", config: "local-tiranti")
  passed &= compare_results(display: "space-shoes", config: "embedded")
  #passed &= compare_results(display: "scarpe-wasm", config: "wasm")
  passed &= compare_results(display: "niente", config: "local")
  passed &= compare_results(display: "gtk-scarpe", config: "local-gtk")
  passed
end

desc "Run shoes-spec for the various implementations"
task "shoes-spec" do
  Dir["results/scarpe-webview/*.yaml"].each { |f| File.unlink f }
  Dir.chdir("implementations/scarpe-webview") do
    Bundler.with_unbundled_env do
      puts "Run Shoes-Spec for Scarpe-Webview"
      system("bundle exec rake shoes-spec")
    end
  end

  Dir["results/space-shoes/*.yaml"].each { |f| File.unlink f }
  Dir.chdir("implementations/space-shoes") do
    Bundler.with_unbundled_env do
      puts "Run Shoes-Spec for SpaceShoes"
      system("bundle exec rake shoes-spec")
    end
  end

  #Dir["results/scarpe-wasm/*.yaml"].each { |f| File.unlink f }
  #Dir.chdir("implementations/scarpe-wasm") do
  #  Bundler.with_unbundled_env do
  #    puts "Run Shoes-Spec for Scarpe-Wasm"
  #    system("bundle exec rake shoes-spec")
  #  end
  #end

  Dir["results/niente/*.yaml"].each { |f| File.unlink f }
  Dir.chdir("implementations/niente") do
    Bundler.with_unbundled_env do
      puts "Run Shoes-Spec for Niente"
      system("bundle exec rake shoes-spec")
    end
  end

  Dir["results/gtk-scarpe/*.yaml"].each { |f| File.unlink f }
  Dir.chdir("implementations/gtk-scarpe") do
    Bundler.with_unbundled_env do
      puts "Run Shoes-Spec for gtk-scarpe"
      system("bundle exec rake shoes-spec")
    end
  end

  passed = compare_all_results

  # If anybody failed, fail the task
  unless passed
    STDERR.puts "One or more spec runs had errors!"
    exit -1
  end
end

task "local-compare" do
  passed = compare_all_results

  # If anybody failed, fail the task
  unless passed
    STDERR.puts "One or more spec runs had errors!"
    exit -1
  end
end

task "perfect-compare" do
  compare_vs_perfect(display: "scarpe-webview", config: "local-tiranti")
  #compare_vs_perfect(display: "scarpe-wasm", config: "wasm")
  compare_vs_perfect(display: "space-shoes", config: "embedded")
  compare_vs_perfect(display: "niente", config: "local")
end

task default: "shoes-spec"

# =============================================================================
# Import Examples from Scarpe
# =============================================================================

SCARPE_PATH = ENV["SCARPE_PATH"] || File.expand_path("../scarpe", __dir__)

desc "Import all examples from Scarpe repo into shoes-spec cases"
task :import_examples, [:source_dir] do |t, args|
  source_dir = args[:source_dir] || "examples/legacy"
  import_scarpe_examples(source_dir)
end

desc "Import working examples from Scarpe"
task :import_working do
  import_scarpe_examples("examples/legacy/working")
end

desc "Import for_playtest examples from Scarpe"
task :import_for_playtest do
  import_scarpe_examples("examples/legacy/for_playtest")
end

desc "Import ALL legacy examples from Scarpe (working + for_playtest)"
task :import_all_legacy do
  import_scarpe_examples("examples/legacy/working")
  import_scarpe_examples("examples/legacy/for_playtest")
end

def import_scarpe_examples(source_subdir)
  source_base = File.join(SCARPE_PATH, source_subdir)
  
  unless File.directory?(source_base)
    STDERR.puts "ERROR: Source directory not found: #{source_base}"
    STDERR.puts "Set SCARPE_PATH env var or ensure ../scarpe exists"
    exit 1
  end
  
  # Target directory mirrors source structure under cases/scarpe_examples/
  target_base = File.join(__dir__, "cases", "scarpe_examples", source_subdir.sub("examples/", ""))
  
  ruby_files = Dir.glob(File.join(source_base, "**", "*.rb"))
  
  puts "Importing #{ruby_files.length} examples from #{source_base}"
  puts "Target: #{target_base}"
  puts
  
  imported = 0
  skipped = 0
  
  ruby_files.each do |rb_file|
    # Compute relative path from source_base
    rel_path = rb_file.sub(source_base + "/", "")
    
    # Change extension to .sspec
    sspec_rel_path = rel_path.sub(/\.rb$/, ".sspec")
    sspec_file = File.join(target_base, sspec_rel_path)
    
    # Skip if already exists
    if File.exist?(sspec_file)
      skipped += 1
      next
    end
    
    # Read original Ruby code (handle encoding issues)
    app_code = File.read(rb_file, encoding: "UTF-8", invalid: :replace, undef: :replace)
    
    # Generate .sspec content
    sspec_content = generate_sspec(app_code, rel_path)
    
    # Create directory if needed
    FileUtils.mkdir_p(File.dirname(sspec_file))
    
    # Write .sspec file
    File.write(sspec_file, sspec_content)
    imported += 1
    
    puts "  ✓ #{sspec_rel_path}"
  end
  
  puts
  puts "Done! Imported: #{imported}, Skipped (existing): #{skipped}"
end

def generate_sspec(app_code, original_path)
  # Extract filename without extension for test name
  test_name = File.basename(original_path, ".rb")
  
  <<~SSPEC
---
# Auto-imported from scarpe/#{original_path}
# TODO: Add meaningful assertions
----------- app code
#{app_code.strip}

----------- test code
# TODO: This test needs real assertions!
# The app runs, but we need to verify behavior.
#
# Example assertions:
#   assert_equal "expected", para().text
#   button().trigger_click
#   assert_equal "after click", para().text
#
# For now, this is a placeholder that will SKIP:
skip "TODO: Add assertions for #{test_name}"
  SSPEC
end
