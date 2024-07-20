# frozen_string_literal: true

require "rbconfig"
require "json"

require "scarpe/components/file_helpers"
require "scarpe/components/port_helpers"
require_relative "../../lib/shoes-spec/test_list"
require_relative "../../lib/shoes-spec/shoes_config"
require_relative "../../lib/shoes-spec/report_results"

require "space_shoes/host/shoes-spec-capybara-test"
Capybara.app_host = "http://localhost:5555"

class SSCapybaraTest < SpaceShoes::ShoesSpecTest
  def with_app(url, &block)
    visit(url)
    assert_selector("#wrapper-wvroot", wait: 5)
    assert_selector("#wrapper-wvroot div", wait: 5)

    yield
  end
end

module SpaceShoes
  module Runner
    include ShoesSpec
    include Scarpe::Components::FileHelpers
    include Scarpe::Components::PortHelpers

    IMPL_DIR = File.expand_path(__dir__)

    def with_server
      server_pid = nil
      STDERR.puts "Dir: #{IMPL_DIR.inspect}"
      Dir.chdir(IMPL_DIR) do
        server_pid = Kernel.spawn("bundle exec ruby -run -e httpd . -p 5555")
        wait_until_port_working("127.0.0.1", 5555)
        yield
      end
    ensure
      Process.kill(9, server_pid) if server_pid
    end

    def html_template(app_code, test_code, test_name:, class_name:)
      <<~HTML_TEMPLATE
        <!DOCTYPE html>
        <html lang="en">
          <head>
          <script type="module" src="spacewalk.js"></script>
          <script type="text/ruby">
            #{app_code}
          </script>
          <script type="text/shoes-spec" data-testname="#{test_name}" data-classname="#{class_name}">
            #{test_code}
          </script>
          </head>
          <body>
          </body>
        </html>
      HTML_TEMPLATE
    end

    def report_space_shoes_specs
      Dir.chdir IMPL_DIR

      system("bundle exec space-shoes --dev src-package packaging") || raise("Failed building packed Wasm file!")

      report = ShoesSpec::ReportResults.new(display: "space-shoes", config: "embedded")

      with_server do
        with_each_loaded_test(display_service: "space-shoes") do |metadata, app_code, test_code|
          begin
            test_name = metadata["test_name"]
            category = metadata["category"]
            class_name = metadata["category"].gsub("/", "_")

            html_contents = html_template(app_code, test_code, test_name:, class_name:)
            # Run test using test_file
            SSCapybaraTest.define_method("test_#{test_name}") do
              with_tempfile(["shoes-spec-space-shoes-code", ".html"], html_contents, dir: IMPL_DIR) do |test_file|
                url = "/" + test_file.split("/").last
                visit(url)
                begin
                  unless has_css?("#wrapper-wvroot", wait: 5) &&
                      has_css?("#wrapper-wvroot div", wait: 5) &&
                      has_css?("div.minitest_result", wait: 5)
                    # No #wrapper-wvroot, print page contents
                    assert false, "SpaceShoes app did not load!"
                  end
                end

                passed = page.evaluate_script('document.shoes_spec.passed')
                #cases = page.evaluate_script('document.shoes_spec.cases')
                #assertions = page.evaluate_script('document.shoes_spec.assertions')
                failures = page.evaluate_script('document.shoes_spec.failures')
                errors = page.evaluate_script('document.shoes_spec.errors')
                skips = page.evaluate_script('document.shoes_spec.skips')
                #err_objects = page.evaluate_script('document.shoes_spec.err_objects')

                result = nil
                if errors > 0
                  result = :error
                elsif failures > 0
                  result = :fail
                elsif skips > 0
                  result = :skip
                else
                  result = :pass
                end
                report.report(result, test_name:, category:)
              end
            end
          end
        end
        Minitest.run []
      end

      report.complete
    end
  end
end
