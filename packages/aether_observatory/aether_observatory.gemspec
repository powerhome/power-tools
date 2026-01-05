# frozen_string_literal: true

require_relative "lib/aether_observatory/version"

Gem::Specification.new do |spec|
  spec.name = "aether_observatory"
  spec.version = AetherObservatory::VERSION
  spec.authors = ["Terry Finn", "Justin Stanczak"]
  spec.email = ["terry.finn@powerhrg.com", "justin.stanczak@powerhrg.com"]

  spec.summary = "Aether Observatory"
  spec.description = "Aether Observatory provides an event broadcast system."
  spec.homepage = "https://github.com/powerhome/power-tools"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/packages/aether_observatory/docs/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "activemodel", ">= 6.1"
  spec.add_dependency "activesupport", ">= 6.1"

  spec.add_development_dependency "appraisal", "~> 2.5.0"
  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "license_finder", "~> 7.0"
  spec.add_development_dependency "pry", ">= 0.14"
  spec.add_development_dependency "pry-byebug", "3.10.1"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov", "0.15.1"
  spec.add_development_dependency "yard", "0.9.21"
end
