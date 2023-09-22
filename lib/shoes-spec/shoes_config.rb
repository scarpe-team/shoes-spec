# frozen_string_literal: true

module ShoesSpec
  extend self

  def which(exe_name)
    exe_dir = ENV['PATH'].split(":").detect { |p| File.exist?("#{p}/#{exe_name}") }
    exe_file = File.expand_path "#{exe_dir}/#{exe_name}"
    unless File.exist?(exe_file)
      raise "Can't find #{exe_name.inspect} executable in path!"
    end
    exe_file
  end

  def loaded_dir_for(path)
    files = $LOADED_FEATURES.select { |s| s.end_with?(path) }
    if files.size == 0
      raise "Couldn't find loaded file: #{path.inspect}!"
    elsif files.size > 1
      raise "Found more than one loaded file: #{path.inspect}!"
    end
    files[0][0..-(path.size + 1)]
  end
end
