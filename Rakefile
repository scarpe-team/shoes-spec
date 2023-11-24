# frozen_string_literal: true

require_relative "lib/shoes-spec/report_results"
require "fileutils"

include ShoesSpec

def compare_all_results
  passed = true
  passed &= compare_results(display: "scarpe-webview", config: "local-calzini")
  passed &= compare_results(display: "scarpe-webview", config: "local-tiranti")
  passed &= compare_results(display: "scarpe-wasm", config: "wasm")
  passed &= compare_results(display: "niente", config: "local")
  passed
end

task "shoes-spec" do
  Dir["results/scarpe-webview/*.yaml"].each { |f| File.unlink f }
  Dir.chdir("implementations/scarpe-webview") do
    Bundler.with_unbundled_env do
      puts "Run Shoes-Spec for Scarpe-Webview"
      system("bundle exec rake shoes-spec")
    end
  end

  Dir["results/scarpe-wasm/*.yaml"].each { |f| File.unlink f }
  Dir.chdir("implementations/scarpe-wasm") do
    Bundler.with_unbundled_env do
      puts "Run Shoes-Spec for Scarpe-Wasm"
      system("bundle exec rake shoes-spec")
    end
  end

  Dir["results/niente/*.yaml"].each { |f| File.unlink f }
  Dir.chdir("implementations/niente") do
    Bundler.with_unbundled_env do
      puts "Run Shoes-Spec for Niente"
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
  compare_vs_perfect(display: "scarpe-wasm", config: "wasm")
  compare_vs_perfect(display: "niente", config: "local")
end

task default: "shoes-spec"
