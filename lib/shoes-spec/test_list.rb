# frozen_string_literal: true

require "scarpe/components/file_helpers"
require "scarpe/components/segmented_file_loader"

module ShoesSpec
  extend self

  ROOT_DIR = File.expand_path File.join(__dir__, "../..")
  CASES_DIR = File.join ROOT_DIR, "cases"
  
  # Discover all directories containing .sspec files (recursive)
  def discover_categories
    # Find all .sspec files recursively
    all_specs = Dir.glob("**/*.sspec", base: CASES_DIR)
    
    # Extract unique parent directories (relative to CASES_DIR)
    categories = all_specs.map { |f| File.dirname(f) }.uniq.sort
    categories
  end
  
  CATEGORIES = discover_categories

  private

  def tests_by_category
    return @tests_by_category if @tests_by_category

    @tests_by_category = {}
    CATEGORIES.each do |category|
      cat_dir = File.join(CASES_DIR, category)
      @tests_by_category[category] = []
      Dir.glob("*.sspec", base: cat_dir).each do |sspec_file|
        item = {
          file: "#{cat_dir}/#{sspec_file}",
          test_name: File.basename(sspec_file, ".sspec"),
          category: category,
        }
        @tests_by_category[category] << item
      end
    end

    @tests_by_category
  end

  public

  # Load each test, segment it into multiple code chunks and call the handler.
  # This loads every test file, and isn't the default when you just
  # want to list out tests by category.
  def with_each_loaded_test(display_service:, &handler)
    tests_by_category.values.each do |items|
      items.each do |item|
        begin
          front_matter, segmap = Scarpe::Components::SegmentedFileLoader.front_matter_and_segments_from_file(File.read item[:file])
          meta = front_matter.merge("file" => item[:file], "test_name" => item[:test_name], "category" => item[:category])
          handler.call(meta, segmap.values[0], segmap.values[1])
        rescue
          STDERR.puts "Error parsing file #{item[:file]}!"
          raise
        end
      end
    end
  end
end
