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
      res_dir = ShoesSpec.results_dir(@display)
      filename = ShoesSpec.results_filename(@config)
      path = "#{res_dir}/#{filename}"
      File.write(path, YAML.dump(out))
      path
    end
  end

  def results_dir(display)
    File.expand_path File.join(__dir__, "../../results/#{display}")
  end

  def results_filename(config)
    "results-#{config}.yaml"
  end

  def compare_results(display:, config:)
    dir = results_dir(display)
    filename = results_filename(config)

    expected = YAML.load(File.read "#{dir}/expected/#{filename}")
    actual = YAML.load(File.read "#{dir}/#{filename}")

    expected_items = expected[:results]
    actual_items = actual[:results]

    unexpected_items = []
    failing_items = []
    passing_items = []

    actual_items.each do |category, h1|
      h1.each do |test_name, result|
        item = [category, test_name, result]
        if expected_items[category] && expected_items[category][test_name]
          exp_res = expected_items[category][test_name]
          if exp_res == result
            # As expected, so do nothing
          elsif exp_res == :pass
            # Expected passing, got a failure or skip
            failing_items << item
          else
            passing_items << item
          end
        else
          unexpected_items.push item
        end
      end
    end

    if unexpected_items.empty? && failing_items.empty? && passing_items.empty?
      puts "Results for #{display}-#{config} are exactly as expected."
    else
      puts "For #{display}-#{config}:"
      puts "  Tests with no expected result:" unless unexpected_items.empty?
      unexpected_items.each do |cat, test, res|
        puts "    * #{cat} / #{test}: #{res}"
      end
      puts "  Tests unexpectedly passing:" unless passing_items.empty?
      passing_items.each do |cat, test, res|
        puts "    * #{cat} / #{test}: #{res}"
      end
      puts "  Tests unexpectedly failing:" unless failing_items.empty?
      failing_items.each do |cat, test, res|
        puts "    * #{cat} / #{test}: #{res}"
      end
      puts "-------"
    end
  end
end
