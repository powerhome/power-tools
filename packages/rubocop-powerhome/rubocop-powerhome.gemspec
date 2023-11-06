# frozen_string_literal: true

require_relative "lib/rubocop/powerhome/version"

Gem::Specification.new do |spec|
  spec.name = "rubocop-powerhome"
  spec.version = RuboCop::Powerhome::VERSION
  spec.authors = ["Carlos Palhares", "Garett Arrowood"]
  spec.email = ["chjunior@gmail.com", "garettarrowood@gmail.com"]

  spec.summary = "Powerhome Rubocop standard rules"
  spec.description = "Powerhome Rubocop standard rules"
  spec.homepage = "https://github.com/powerhome/power_linting"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html

  spec.add_runtime_dependency "rubocop", "~> 1.52.0"
  spec.add_runtime_dependency "rubocop-performance"
  spec.add_runtime_dependency "rubocop-rails"
  spec.add_runtime_dependency "rubocop-rake"
  spec.add_runtime_dependency "rubocop-rspec"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.add_development_dependency "appraisal", "~> 2.4.1"
  spec.add_development_dependency "license_finder", "~> 7.0"
  spec.add_development_dependency "pry", ">= 0.14.2"
  spec.add_development_dependency "pry-byebug", "3.10.1"
  spec.add_development_dependency "rails", ">= 6.0.6.1", "< 7.1"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
