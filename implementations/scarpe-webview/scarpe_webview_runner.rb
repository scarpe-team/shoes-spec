module Scarpe
  module Webview
    module Runner
      def run_scarpe_command_line metadata, app_code, test_code
        with_tempfiles(
          [
            ["shoes-spec-scarpe-test-app", app_code],
            ["shoes-spec-scarpe-test-code", test_code],
          ]) do |app_file, test_code_file|
            # TODO: env vars SCARPE_LOG_CONFIG, SCARPE_TEST_RESULTS, LOCALAPPDATA=Dir.tmpdir
            ENV["SHOES_SPEC_TEST"] = test_code_file
            ENV["SHOES_MINITEST_EXPORT_FILE"] = "sspec.json"
            ENV["SHOES_MINITEST_CLASS_NAME"] = metadata["category"].gsub("/", "_")
            ENV["SHOES_MINITEST_METHOD_NAME"] = metadata["test_name"]
            system(RbConfig.ruby, which("scarpe"), "--dev", app_file)
        end
      end
    end
  end
end
