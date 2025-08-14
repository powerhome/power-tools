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
  s.required_ruby_version = ">= 3.0"

  s.metadata["rubygems_mfa_required"] = "true"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile", "docs/README.md"]

  s.add_dependency "attr_encrypted", "4.0.0"
  s.add_dependency "nitro_config"

  s.add_dependency "rails", ">= 6.0.6.1", "< 8"
end
