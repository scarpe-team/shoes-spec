# frozen_string_literal: true

require "rbconfig"

require_relative "../../lib/shoes-spec/test_list"
require_relative "../../lib/shoes-spec/shoes_config"

require "scarpe/wasm/shoes-spec"

module Scarpe
  module Wasm
    module Runner
      include Scarpe::Wasm::PortUtils
      include ShoesSpec

      # Wasm is fun. We can build the Scarpe-Wasm code into
      # a reusable package and serve it via webrick.
      # We'd like to run webrick (a.k.a. Ruby's default httpd)
      # once, but for each spec we'll host the app code
      # as a .rb file served by webrick, then run the test
      # code on the host via Capybara.
      def run_all_shoes_specs
        test_dir = File.join(File.expand_path(__dir__), "pkg_dir")
        port_num = 4327
        Capybara.default_driver = :selenium_chrome_headless
        Capybara.run_server = false
        Capybara.app_host = "http://localhost:#{port_num}"

        # Create this every time to be sure we have latest and match Gemfile.lock
        Dir.chdir __dir__ do
          mkdir_p "pkg_dir/src"
          touch "pkg_dir/src/APP_NAME.rb"
          system "scarpe-wasm --dev src-package pkg_dir/ pkg_dir/"
        end

        Dir.chdir test_dir

        retries = 0
        httpd_pid = fork do
          if port_working?("localhost", port_num)
            system("pkill -f 'ruby -run -e httpd . -p #{port_num}'")
          end

          Bundler.with_unbundled_env do
            system("bundle exec ruby -run -e httpd . -p #{port_num}")
          end
        end
        at_exit do
          system("pkill -f 'ruby -run -e httpd . -p #{port_num}'")
        end

        require "minitest/autorun"
        with_each_loaded_test(display_service: "scarpe-wasm") do |metadata, app_code, test_code|
          cat = metadata["category"].gsub("/", "_")
          test_name = "#{cat}_#{metadata["test_name"]}".gsub(".sspec", ".rb")

          rb_file = "spec_#{test_name}"
          File.write(rb_file, app_code) # Write Ruby app-source file

          index_file = "index-#{test_name}.html"
          index_contents = File.read("index.html").gsub("APP_NAME.rb", rb_file).gsub("8080", port_num.to_s)
          File.write(index_file, index_contents)

          test_class = get_test_class_for_category(cat)
          test_class.define_method("test_#{metadata["test_name"]}") do
            run_shoes_spec_code("/" + index_file) { eval test_code }
          end
        end

        puts "Start Minitest autorun..."
      end

      # Name must not start with "test"
      def get_test_class_for_category(category)
        @test_classes ||= {}
        @test_classes[category] ||= Class.new(Scarpe::Wasm::CapybaraTestCase)
      end
    end
  end
end
