# frozen_string_literal: true

require_relative "lib/cygnet/version"

Gem::Specification.new do |s|
  s.name        = "cygnet"
  s.version     = Cygnet::VERSION
  s.authors     = ["Carlos Palhares", "Jill Klang"]
  s.email       = ["chjunior@gmail.com", "jillian.emilie@gmail.com"]

  s.summary     = "Better ways to account for nil."
  s.description = "Implements the Null Object Pattern and an implmentation of nested hashes using NullObject."
  s.homepage = "https://github.com/powerhome/power-tools"
  s.license = "MIT"
  s.required_ruby_version = ">= 2.7"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile", "docs/README.md"]
  s.require_paths = ["lib"]

  s.add_development_dependency "appraisal", "~> 2.5.0"
  s.add_development_dependency "bundler", "~> 2.1"
  s.add_development_dependency "license_finder", "~> 7.0"
  s.add_development_dependency "pry", ">= 0.14"
  s.add_development_dependency "pry-byebug", "3.10.1"
  s.add_development_dependency "rainbow", "2.2.2"
  s.add_development_dependency "rake", "~> 13.0"
  s.add_development_dependency "rspec", "~> 3.0"
  s.add_development_dependency "simplecov", "0.15.1"
  s.add_development_dependency "test-unit", "3.1.5"
  s.add_development_dependency "yard", "0.9.21"
  s.metadata["rubygems_mfa_required"] = "true"
end
