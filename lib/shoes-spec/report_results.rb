# frozen_string_literal: true

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

    RESULTS = [:pass, :fail, :skip, :error]
    def report(result, test_name:, category:)
      raise "Unknown result #{result.inspect}! Should be one of: #{RESULTS.inspect}!" unless RESULTS.include?(result)

      @results[category] ||= {}
      @results[category][test_name] = result
    end

    def complete
      out_results = {}
      @results.keys.sort.each do |cat|
        out_results[cat] = {}
        @results[cat].keys.sort.each do |test_name|
          out_results[cat][test_name] = @results[cat][test_name]
        end
      end
      out = {
        display: @display,
        config: @config,
        results: out_results,
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

  def compare_expected_actual(name, expected_items, actual_items)
    unexpected_items = []
    incorrect_items = []
    not_present_items = []

    actual_items.each do |category, h1|
      h1.each do |test_name, result|
        item = [category, test_name, result]
        if expected_items[category] && expected_items[category][test_name]
          exp_res = expected_items[category][test_name]
          if exp_res == result
            # As expected, so do nothing
          else
            incorrect_items << [category, test_name, exp_res, result]
          end
        else
          unexpected_items.push item
        end
      end
    end

    expected_items.each do |category, h1|
      h1.each do |test_name, result|
        item = [category, test_name, result]
        unless actual_items[category] && actual_items[category][test_name]
          not_present_items << item
        end
      end
    end

    if unexpected_items.empty? && incorrect_items.empty? && not_present_items.empty?
      puts "Results for #{name} are exactly as expected."
      puts "-------"
      true
    else
      puts "For #{name}:"
      puts "  Tests with no expected result:" unless unexpected_items.empty?
      unexpected_items.each do |cat, test, res|
        puts "    * #{cat} / #{test}: #{res}"
      end
      puts "  Tests with unexpected incorrect results:" unless incorrect_items.empty?
      incorrect_items.each do |cat, test, exp_res, actual_res|
        puts "    * #{cat} / #{test}: expected: #{exp_res} actual: #{actual_res}"
      end
      puts "  Expected tests not present:" unless not_present_items.empty?
      not_present_items.each do |cat, test, res|
        puts "    * #{cat} / #{test}: #{res}"
      end
      puts "-------"
      false
    end
  end

  def compare_results(display:, config:)
    dir = results_dir(display)
    filename = results_filename(config)

    expected = YAML.load(File.read "#{dir}/expected/#{filename}")
    actual = YAML.load(File.read "#{dir}/#{filename}")

    compare_expected_actual("#{display}-#{config}", expected[:results], actual[:results])
  end

  def compare_vs_perfect(display:, config:, compare_expected: true)
    dir = results_dir(display)
    ideal_dir = results_dir("ideal")
    filename = results_filename(config)

    expected = YAML.load(File.read "#{ideal_dir}/results-perfect.yaml")
    actual = YAML.load(File.read "#{dir}/#{compare_expected ? "expected/" : ""}#{filename}")

    compare_expected_actual("#{display}-#{config}", expected[:results], actual[:results])
  end
end
