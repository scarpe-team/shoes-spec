# frozen_string_literal: true

require_relative "test_list"

require "yaml"

module ShoesSpec
  class ReportResults
    def initialize(display:, config: {})
      @display = display
      @config = config

      raise "Display service name must be a string!" unless @display.is_a?(String)
      raise "Display service configuration must be a string!" unless @config.is_a?(String)

      @results = {}
    end

    RESULTS = [:pass, :fail, :skip]
    def report(result, test_name:, category:)
      raise "Unknown result #{result.inspect}! Should be one of: #{RESULTS.inspect}!" unless RESULTS.include?(result)

      @results[category] ||= {}
      @results[category][test_name] = result
    end

    def complete
      out = {
        display: @display,
        config: @config,
        results: @results,
      }
      results_dir = File.expand_path File.join(__dir__, "../../results/#{@display}")
      path = "#{results_dir}/results-#{@config}.yaml"
      File.write(path, YAML.dump(out))
      path
    end
  end
end
