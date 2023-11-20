# frozen_string_literal: true

require "rbconfig"
require "json"

require "scarpe/components/file_helpers"
require "scarpe/components/minitest_result"
require_relative "../../lib/shoes-spec/test_list"
require_relative "../../lib/shoes-spec/shoes_config"
require_relative "../../lib/shoes-spec/report_results"

module Niente
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

          # TODO: LOCALAPPDATA=Dir.tmpdir
          ENV["SHOES_SPEC_TEST"] = test_code_file
          ENV["SCARPE_DISPLAY_SERVICE"] = "niente"
          ENV["SHOES_MINITEST_EXPORT_FILE"] = sspec_file
          ENV["SHOES_MINITEST_CLASS_NAME"] = metadata["category"].gsub("/", "_")
          ENV["SHOES_MINITEST_METHOD_NAME"] = metadata["test_name"].gsub(".sspec", "")
          res = system(RbConfig.ruby, which("scarpe"), "--dev", app_file)
          return res ? sspec_file : nil
      end
    end

    def report_niente_specs
      report = ShoesSpec::ReportResults.new(display: "niente", config: "local")

      with_each_loaded_test(display_service: "niente") do |metadata, app_code, test_code|
        begin
          test_name = metadata["test_name"]
          category = metadata["category"]

          result_file = run_scarpe_command_line_test(metadata, app_code, test_code)

          if result_file == nil
            report.report(:error, test_name:, category:)
            next
          end

          mtr = Scarpe::Components::MinitestResult.new(result_file)

          if mtr.error?
            result = :error
          elsif mtr.fail?
            result = :fail
          elsif mtr.skip?
            result = :skip
          else
            result = :pass
          end
          report.report(result, test_name:, category:)
        end
      end

      report.complete
    end
  end
end
