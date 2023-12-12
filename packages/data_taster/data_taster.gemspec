# frozen_string_literal: true

require_relative "lib/data_taster/version"

Gem::Specification.new do |spec|
  spec.name        = "data_taster"
  spec.version     = DataTaster::VERSION
  spec.authors     = ["Jill Klang"]
  spec.email       = ["jillian.emilie@gmail.com"]

  spec.summary = "Delicious and sanitized data samples for development and testing."
  spec.description = "Export, sanitize, and import data to help develop better apps."
  spec.homepage = "https://github.com/powerhome/power-tools"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/packages/data_taster/docs/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", "6.0.6.1"

  spec.add_development_dependency "license_finder", "~> 7.0"
  spec.add_development_dependency "rubocop-powerhome", "0.5.0"

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "parser", ">= 2.5", "!= 2.5.1.1"
  spec.add_development_dependency "rainbow", "2.2.2"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov", "0.15.1"
  spec.add_development_dependency "test-unit", "3.1.5"
  spec.add_development_dependency "yard", "0.9.34"
end
