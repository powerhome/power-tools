# frozen_string_literal: true

require_relative "lib/wayfinding/version"

Gem::Specification.new do |s|
  s.name        = "wayfinding"
  s.version     = Wayfinding::VERSION
  s.authors     = ["Nitro Developers"]
  s.email       = ["dev@powerhrg.com"]

  s.summary     = "Cross-application URL resolution."
  s.description = "A global registry of named destinations, so any component can link to any page " \
                  "without depending on the component that owns the route."
  s.homepage = "https://github.com/powerhome/power-tools"
  s.license = "MIT"
  s.required_ruby_version = ">= 3.2"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile", "docs/README.md"]
  s.require_paths = ["lib"]

  s.add_dependency "rails", ">= 7.1"

  s.add_development_dependency "appraisal", "~> 2.5.0"
  s.add_development_dependency "bundler", "~> 2.1"
  s.add_development_dependency "license_finder", "~> 7.0"
  s.add_development_dependency "pry", ">= 0.14"
  s.add_development_dependency "pry-byebug", "3.10.1"
  s.add_development_dependency "rainbow", "3.1.1"
  s.add_development_dependency "rake", "~> 13.0"
  s.add_development_dependency "rspec", "~> 3.0"
  s.add_development_dependency "simplecov", "0.15.1"
  s.add_development_dependency "yard", "0.9.38"
  s.metadata["rubygems_mfa_required"] = "true"
end
