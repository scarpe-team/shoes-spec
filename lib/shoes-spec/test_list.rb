# frozen_string_literal: true

require "scarpe/components/file_helpers"
require "scarpe/components/segmented_file_loader"
require "scarpe/components/errors"

module ShoesSpec
  extend self

  ROOT_DIR = File.expand_path File.join(__dir__, "../..")
  CASES_DIR = File.join ROOT_DIR, "cases"
  CATEGORIES = Dir.glob("*/*", base: CASES_DIR).select do |f|
    File.directory?("#{CASES_DIR}/#{f}") # e.g. "drawables/button"
  end

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
        rescue
          STDERR.puts "Error parsing file #{item[:file]}!"
          raise
        end
        meta = front_matter.merge("file" => item[:file], "test_name" => item[:test_name], "category" => item[:category])
        handler.call(meta, segmap.values[0], segmap.values[1])
      end
    end
  end
end
