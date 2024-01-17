# frozen_string_literal: true

require_relative "lib/lumberaxe/version"

Gem::Specification.new do |spec|
  spec.name        = "lumberaxe"
  spec.version     = Lumberaxe::VERSION
  spec.authors     = ["Carlos Palhares", "Jill Klang"]
  spec.email       = ["chjunior@gmail.com", "jillian.emilie@gmail.com"]

  spec.summary     = "Power-ful logging wrapper"
  spec.description = "Lumberaxe handles logging output formatting."
  spec.homepage = "https://github.com/powerhome/power-tools"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/packages/lumberaxe/docs/CHANGELOG.md"

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

  spec.add_dependency "activesupport", ">= 6.0.6.1", "< 7.2"
  spec.add_dependency "lograge", "0.10.0"

  spec.add_development_dependency "appraisal", "~> 2.4.1"
  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "combustion", "~> 1.3"
  spec.add_development_dependency "license_finder", ">= 7.0"
  spec.add_development_dependency "parser", ">= 2.5", "!= 2.5.1.1"
  spec.add_development_dependency "pry", ">= 0.14.2"
  spec.add_development_dependency "pry-byebug", "3.10.1"
  spec.add_development_dependency "rails", ">= 6.0.6.1", "< 7.2"
  spec.add_development_dependency "rainbow", "2.2.2"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-rails", "~> 5.1.2"
  spec.add_development_dependency "rubocop-powerhome", "0.5.0"
  spec.add_development_dependency "simplecov", "0.15.1"
  spec.add_development_dependency "sqlite3", "~> 1.4.2"
  spec.add_development_dependency "test-unit", "3.1.5"
  spec.add_development_dependency "yard", "0.9.21"
end
