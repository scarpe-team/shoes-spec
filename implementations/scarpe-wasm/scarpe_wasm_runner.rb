# frozen_string_literal: true

require "rbconfig"

require 'selenium-webdriver'

require "scarpe/components/minitest_result"

require_relative "../../lib/shoes-spec/test_list"
require_relative "../../lib/shoes-spec/shoes_config"
require_relative "../../lib/shoes-spec/report_results"

require "scarpe/wasm/shoes-spec"

module Scarpe
  module Wasm
    module Runner
      include Scarpe::Wasm::PortUtils
      include ShoesSpec

      class << self
        attr_accessor :reporter
      end

      def prepare_package_dir
        # Create this every time to be sure we have latest and match Gemfile.lock
        Dir.chdir __dir__ do
          cp "Gemfile", "pkg_dir/"
          cp "Gemfile.lock", "pkg_dir/"
          mkdir_p "pkg_dir/src"
          touch "pkg_dir/src/APP_NAME.rb"
          Dir.chdir "pkg_dir" do
            # The Gemfile changes slightly -- local paths for gems change... So bundle install again.
            Bundler.with_unbundled_env do
              system("bundle") || raise("Couldn't update Gemfile.lock for pkg_dir!")
            end
          end
          system "scarpe-wasm --dev src-package pkg_dir/ pkg_dir/" || raise("Couldn't package scarpe-wasm!")
        end
      end

      # Start an HTTP server in a background process, return a PID
      def start_http_server(port_num: 4327)
        httpd_pid = nil
        command = "ruby -run -e httpd . -p #{port_num}"

        test_dir = File.join(File.expand_path(__dir__), "pkg_dir")
        Dir.chdir test_dir do
          httpd_pid = fork do
            if port_working?("localhost", port_num)
              system("pkill -f '#{command}'")
            end

            Bundler.with_unbundled_env do
              puts "Running HTTP server: #{command.inspect}"
              system("bundle exec #{command}") || raise("Couldn't start httpd for scarpe-wasm testing!")
            end
          end
          at_exit do
            system("pkill -f '#{command}'")
          end
        end
        httpd_pid
      end

      # Wasm is fun. We can build the Scarpe-Wasm code into
      # a reusable package and serve it via webrick.
      # We'd like to run webrick (a.k.a. Ruby's default httpd)
      # once, but for each spec we'll host the app code
      # as a .rb file served by webrick, then run the test
      # code on the host via Capybara.
      def run_all_shoes_specs
        test_dir = File.join(File.expand_path(__dir__), "pkg_dir")
        port_num = 4327
        Capybara.register_driver :logging_selenium_chrome do |app|
          options = Selenium::WebDriver::Chrome::Options.new
          options.add_option("goog:loggingPrefs", {browser: 'ALL'})
          options.add_argument("--headless")

          Capybara::Selenium::Driver.new(app,
                                         options:,
                                         browser: :chrome,
                                         )
        end
        Capybara.default_driver = :logging_selenium_chrome
        Capybara.run_server = false
        Capybara.app_host = "http://localhost:#{port_num}"

        prepare_package_dir

        httpd_pid = start_http_server(port_num:)

        Scarpe::Wasm::Runner.reporter = ShoesSpec::ReportResults.new(display: "scarpe-wasm", config: "wasm")

        Dir.chdir test_dir

        require "minitest/autorun"
        with_each_loaded_test(display_service: "scarpe-wasm") do |metadata, app_code, test_code|
          cat = metadata["category"]
          test_name = "#{cat.gsub("/", "_")}_#{metadata["test_name"]}".gsub(".sspec", ".rb")

          rb_file = "spec_#{test_name}.rb"
          File.write(rb_file, app_code) # Write Ruby app-source file

          index_file = "index-#{test_name}.html"
          index_contents = File.read("index.html").gsub("APP_NAME.rb", rb_file).gsub("8080", port_num.to_s)
          File.write(index_file, index_contents)

          test_class = get_test_class_for_category(cat)
          test_class.define_method("test_#{metadata["test_name"]}") do
            run_shoes_spec_code("/" + index_file) { eval test_code }
          end
        end

        Minitest.after_run do
          path = Scarpe::Wasm::Runner.reporter.complete
          puts "Wrote ShoesSpec results to #{path}"
          compare_results(display: "scarpe-wasm", config: "wasm")
        end

        puts "Start Minitest autorun..."
      end

      def manual_shoes_spec_run
        test_dir = File.join(File.expand_path(__dir__), "pkg_dir")
        port_num = 4327

        prepare_package_dir

        puts "HTTP server: \"ruby -run -e httpd . -p #{port_num}\""
        #httpd_pid = start_http_server(port_num:)

        Dir.chdir test_dir
        with_each_loaded_test(display_service: "scarpe-wasm") do |metadata, app_code, test_code|
          cat = metadata["category"]
          test_name = "#{cat.gsub("/", "_")}_#{metadata["test_name"]}".gsub(".sspec", ".rb")

          rb_file = "spec_#{test_name}.rb"
          File.write(rb_file, app_code) # Write Ruby app-source file

          index_file = "index-#{test_name}.html"
          index_contents = File.read("index.html").gsub("APP_NAME.rb", rb_file).gsub("8080", port_num.to_s)
          File.write(index_file, index_contents)

          puts "Test: #{metadata["category"]}/#{metadata["test_name"]}: http://localhost:#{port_num}/#{index_file}"
        end
      end

      def get_test_class_for_category(category)
        @test_classes ||= {}
        return @test_classes[category] if @test_classes[category]
        new_class = Class.new(Scarpe::Wasm::CapybaraReportingTestCase)
        new_class.class_eval do
          class << self
            attr_accessor :category
          end
        end
        new_class.category = category
        @test_classes[category] = new_class
      end
    end

    class CapybaraReportingTestCase < Scarpe::Wasm::CapybaraTestCase
      def teardown
        test_name = self.name.gsub(/^test_/, "")
        category = self.class.category
        if passed?
          res = :pass
        elsif skipped?
          res = :skip
        elsif error?
          res = :error
        else
          res = :fail
        end
        Scarpe::Wasm::Runner.reporter.report res, test_name: test_name, category: category

        super
      end
    end
  end
end
