# frozen_string_literal: true

require "rbconfig"
require "json"

require "scarpe/components/file_helpers"
require_relative "../../lib/shoes-spec/test_list"
require_relative "../../lib/shoes-spec/shoes_config"
require_relative "../../lib/shoes-spec/report_results"

module Scarpe
  module Webview
    module Runner
      include ShoesSpec
      include Scarpe::Components::FileHelpers

      def run_scarpe_command_line_test metadata, app_code, test_code
        with_tempfiles(
          [
            ["shoes-spec-scarpe-test-app", app_code],
            ["shoes-spec-scarpe-test-code", test_code],
          ]) do |app_file, test_code_file|
            sspec_file = File.expand_path "sspec.json"

            # TODO: env vars SCARPE_LOG_CONFIG, LOCALAPPDATA=Dir.tmpdir, etc.
            ENV["SHOES_SPEC_TEST"] = test_code_file
            ENV["SCARPE_DISPLAY_SERVICE"] = "wv_local"
            ENV["SCARPE_HTML_RENDERER"] = "calzini"
            ENV["SHOES_MINITEST_EXPORT_FILE"] = sspec_file
            ENV["SHOES_MINITEST_CLASS_NAME"] = metadata["category"].gsub("/", "_")
            ENV["SHOES_MINITEST_METHOD_NAME"] = metadata["test_name"].gsub(".sspec", "")
            system(RbConfig.ruby, which("scarpe"), "--dev", app_file)
            return File.read(sspec_file)
        end
      end

      def report_webview_specs
        report = ShoesSpec::ReportResults.new(display: "scarpe-webview", config: "local-calzini")

        with_each_loaded_test(display_service: "scarpe-webview") do |metadata, app_code, test_code|
          res = JSON.load run_scarpe_command_line_test(metadata, app_code, test_code)
          unless res.is_a?(Array) && res.size == 1
            raise "Internal error! Unexpected result format from run_scarpe_command_line_test!"
          end
          res = res[0]

          test_name = metadata["test_name"]
          category = metadata["category"]
          if res["failures"].empty?
            report.report(:pass, test_name:, category:)
          else
            report.report(:fail, test_name:, category:)
          end
        end

        path = report.complete
        puts "Wrote ShoesSpec results to #{path}"
        compare_results(display: "scarpe-webview", config: "local-calzini")
      end
    end
  end
end
