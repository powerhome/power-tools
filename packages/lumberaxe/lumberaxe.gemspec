# frozen_string_literal: true

require_relative "lib/lumberaxe/version"

$LOAD_PATH.push File.expand_path("lib", __dir__)

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

  spec.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile", "docs/README.md"]

  spec.add_dependency "activesupport", ">= 5.2.8.1"
  spec.add_dependency "lograge", "0.10.0"

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "license_finder", "~> 7.0"
  spec.add_development_dependency "parser", ">= 2.5", "!= 2.5.1.1"
  spec.add_development_dependency "pry-byebug", "3.9.0"
  spec.add_development_dependency "rainbow", "2.2.2"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop-powerhome", "0.5.0"
  spec.add_development_dependency "simplecov", "0.15.1"
  spec.add_development_dependency "test-unit", "3.1.5"
  spec.add_development_dependency "yard", "0.9.21"
end
