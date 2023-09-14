# frozen_string_literal: true

require_relative "lib/shoes-spec/version"

Gem::Specification.new do |spec|
  spec.name = "shoes-spec"
  spec.version = ShoesSpec::VERSION
  spec.authors = ["Noah Gibbs", "Scarpe Team"]
  spec.email = ["the.codefolio.guy@gmail.com"]

  spec.summary = "The Shoes Spec intends to test Shoes capability and compliance for different display libraries."
  #spec.description = "TODO: Write a longer description or delete this line."
  spec.homepage = "https://github.com/scarpe-team/shoes-spec"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  #spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  #spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Use functionality from Scarpe-Components, which should be okay with other Shoes-based libs
  spec.add_dependency "scarpe-components" #, "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
