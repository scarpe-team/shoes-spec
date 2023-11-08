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

  compare_results(display: "scarpe-webview", config: "local-calzini")
  compare_results(display: "scarpe-wasm", config: "wasm")
end

task default: "shoes-spec"