# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require_relative "lib/nitro_config/version"

Gem::Specification.new do |s|
  s.name        = "nitro_config"
  s.version     = NitroConfig::VERSION
  s.authors     = ["Carlos Palhares", "Jill Klang"]
  s.email       = ["chjunior@gmail.com", "jillian.emilie@gmail.com"]
  s.homepage    = "https://github.com/powerhome/power-tools/blob/main/packages/nitro_config/docs/README.md"
  s.summary     = "Nitro Configuration Loader"
  s.description = "Loads Nitro configuration and makes it available to the application"

  s.license = "MIT"
  s.required_ruby_version = ">= 2.7"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile", "docs/README.md"]

  if ENV["RAILS_NEXT"]
    s.add_dependency "activesupport", "6.0.5"
  else
    s.add_dependency "activesupport", "5.2.8"
  end

  s.add_development_dependency "license_finder", "~> 7.0"
  s.add_development_dependency "pry-byebug", "3.9.0"
  s.add_development_dependency "rainbow", "2.2.2"
  s.add_development_dependency "rake", "~> 13.0"
  s.add_development_dependency "rspec", "3.9.0"
  s.add_development_dependency "rubocop-powerhome", "0.4.1"
  s.add_development_dependency "simplecov", "0.15.1"
  s.add_development_dependency "yard", "0.9.21"
end
