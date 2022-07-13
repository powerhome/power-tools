# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

Gem::Specification.new do |s|
  s.name        = "nitro_config"
  s.version     = NitroConfig::VERSION
  s.authors     = ["Nitro Developers"]
  s.email       = ["dev@powerhrg.com"]
  s.homepage    = "http://nitro.powerhrg.com"
  s.summary     = "Nitro Configuration Loader"
  s.description = "Loads Nitro configuration and makes it available to the application"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  raise "RubyGems 2.0 or newer is required to protect against public gem pushes." unless s.respond_to?(:metadata)

  s.metadata["allowed_push_host"] = "http://rubygems.powerhrg.com"
  s.license = "LicenseRef-NitroComponent"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile", "docs/README.md"]

  if ENV["RAILS_NEXT"]
    s.add_dependency "activesupport", "6.0.5"
  else
    s.add_dependency "activesupport", "5.2.8"
  end

  s.add_development_dependency "nitro_linting", "0.0.1"
  s.add_development_dependency "pry-byebug", "3.9.0"
  s.add_development_dependency "rainbow", "2.2.2"
  s.add_development_dependency "rake", "~> 13.0"
  s.add_development_dependency "rspec", "3.9.0"
  s.add_development_dependency "simplecov", "0.15.1"
  s.add_development_dependency "yard", "0.9.21"
end
