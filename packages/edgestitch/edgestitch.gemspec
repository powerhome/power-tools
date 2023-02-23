# frozen_string_literal: true

require_relative "lib/edgestitch/version"

Gem::Specification.new do |spec|
  spec.name        = "edgestitch"
  spec.version     = Edgestitch::VERSION
  spec.authors     = ["Carlos Palhares"]
  spec.email       = ["chjunior@gmail.com"]

  spec.description = spec.summary = "Edgestitch allows engines to define partial structure-self.sql files to be " \
                                    "stitched into a single structure.sql file by the umbrella application."
  spec.homepage = "https://github.com/powerhome/power-tools"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/packages/edgestitch/docs/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "license_finder", ">= 7.0"
  spec.add_development_dependency "mysql2", "0.5.3"
  spec.add_development_dependency "rails", ">= 5.2.8.1", "< 7.1"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-rails", "~> 5.1.2"
  spec.add_development_dependency "rubocop-powerhome", "0.5.0"
  spec.add_development_dependency "simplecov", "0.15.1"
  spec.add_development_dependency "yard", "0.9.21"
end
