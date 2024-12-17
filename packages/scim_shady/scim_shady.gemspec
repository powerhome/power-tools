# frozen_string_literal: true

require_relative "lib/scim_shady/version"

Gem::Specification.new do |spec|
  spec.name = "scim_shady"
  spec.version = ScimShady::VERSION
  spec.authors = ["Carlos Palhares"]
  spec.email = ["chjunior@gmail.com"]

  spec.summary = "Active Record like model for SCIM"
  spec.description = "ScimShady is object model on the ActiveRecord pattern for a SCIM backend"
  spec.homepage = "https://powerhrg.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/powerhome/power-tools"
  spec.metadata["changelog_uri"] = "https://github.com/powerhome/power-tools"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activemodel", "> 6.0", "< 7.2"
end
