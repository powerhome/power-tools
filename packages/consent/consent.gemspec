# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "consent/version"

Gem::Specification.new do |spec|
  spec.name          = "consent"
  spec.version       = Consent::VERSION
  spec.authors       = ["Carlos Palhares"]
  spec.email         = ["chjunior@gmail.com"]

  spec.summary       = "Consent permission based authorization"
  spec.description   = "Consent permission based authorization"
  spec.homepage = "https://github.com/powerhome/power-tools"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7"

  spec.files = `git ls-files`.split.grep_v(/^(test|spec|features)/)
  spec.require_paths = ["lib"]

  spec.add_dependency "cancancan", "3.2.1"

  spec.add_development_dependency "activerecord", ">= 5"
  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "combustion", "~> 1.3"
  spec.add_development_dependency "license_finder", ">= 7.0"
  spec.add_development_dependency "pry", ">= 0.14.2"
  spec.add_development_dependency "pry-byebug", "3.10.1"
  spec.add_development_dependency "rake", "~> 13"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-rails", "~> 5.1.2"
  spec.add_development_dependency "rubocop-powerhome", "0.5.0"
  spec.add_development_dependency "sqlite3", "~> 1.4.2"
  spec.metadata["rubygems_mfa_required"] = "true"
end
