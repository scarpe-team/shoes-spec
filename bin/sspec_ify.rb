#!/usr/bin/env ruby

# Want to use this script on a whole subtree? Find is your friend.
# Something like:
#    find . -name "*.rb" -exec ../../../bin/sspec_ify.rb --git \{\} \;

# If the script gets the --git param, it will git add and git rm the file,
# not just modify and delete it.
use_git = ARGV.delete("--git")

if ARGV.size != 1
  raise "Please specify a single .rb file to sspec-ify."
end

old_file = ARGV[0]

file_text = File.read old_file
indented_text = file_text.split("\n").map { |s| "  " + s }.join("\n")

sspec_text = <<SSPEC
---
----------- app code
#{indented_text}
----------- test code
assert true, "Assert that test code runs at all."
SSPEC

new_file = old_file.gsub(/\.rb\Z/, ".sspec")
File.write(new_file, sspec_text)
File.unlink old_file

if use_git
  system "git rm #{old_file}" || raise("Can't git rm #{old_file.inspect}!")
  system "git add #{new_file}" || raise("Can't git add #{new_file.inspect}!")
end

