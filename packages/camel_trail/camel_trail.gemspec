# frozen_string_literal: true

require_relative "lib/camel_trail/version"

Gem::Specification.new do |s|
  s.name        = "camel_trail"
  s.version     = CamelTrail::VERSION
  s.authors     = ["Gurban Haydarov"]
  s.email       = ["gurban@hey.com"]
  s.summary     = "Simple way to track database changes"
  s.description = "CamelTrail makes it easy to keep a history of attribute changes on a model"

  s.homepage = "https://github.com/powerhome/power-tools"
  s.license = "MIT"
  s.required_ruby_version = ">= 2.7"

  s.metadata["rubygems_mfa_required"] = "true"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile", "docs/README.md"]

  s.add_dependency "nitro_config"
  s.add_dependency "attr_encrypted", "4.0.0"

  s.add_dependency "rails", ">= 6.0.6.1", "< 7.2"

  s.add_development_dependency "appraisal", "~> 2.4.1"
  s.add_development_dependency "license_finder", ">= 7.0"
  s.add_development_dependency "rake", "~> 13"
  s.add_development_dependency "rspec", "~> 3.0"
  s.add_development_dependency "rspec-rails", "~> 5.1.2"
  s.add_development_dependency "rubocop-powerhome", "0.5.0"
  s.add_development_dependency "simplecov", "0.15.1"
  s.add_development_dependency "sqlite3", "~> 1.4.2"
  s.add_development_dependency "yard", "0.9.21"
end
