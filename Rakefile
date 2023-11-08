# frozen_string_literal: true

require_relative "lib/shoes-spec/report_results"

require "fileutils"

task "shoes-spec" do
  include ShoesSpec

  Dir["results/scarpe-webview/*.yaml"].each { |f| File.unlink f }
  Dir["results/scarpe-wasm/*.yaml"].each { |f| File.unlink f }

  Dir.chdir("implementations/scarpe-webview") do
    Bundler.with_unbundled_env do
      puts "Run Shoes-Spec for Scarpe-Webview with Calzini"
      system("bundle exec rake shoes-spec")
    end
  end

  Dir.chdir("implementations/scarpe-wasm") do
    Bundler.with_unbundled_env do
      puts "Run Shoes-Spec for Scarpe-Wasm"
      system("bundle exec rake shoes-spec")
    end
  end

  passed = true
  passed &= compare_results(display: "scarpe-webview", config: "local-calzini")
  passed &= compare_results(display: "scarpe-wasm", config: "wasm")

  # If anybody failed, fail the task
  unless passed
    STDERR.puts "One or more spec runs had errors!"
    exit -1
  end
end

task default: "shoes-spec"