# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

Gem::Specification.new do |s|
  s.name        = "lumberaxe"
  s.version     = "0.0.1"
  s.authors     = ["Nitro Developers"]
  s.email       = ["dev@powerhrg.com"]
  s.homepage    = "http://nitro.powerhrg.com"
  s.summary     = "SomeSummary"
  s.description = "SomeLongerDescription"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  raise "RubyGems 2.0 or newer is required to protect against public gem pushes." unless s.respond_to?(:metadata)

  s.metadata["allowed_push_host"] = "http://rubygems.powerhrg.com"
  s.license = "LicenseRef-NitroComponent"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile", "docs/README.md"]

  s.add_dependency "activesupport", "5.2.8.1"

  s.add_development_dependency "bundler", "~> 2.1"
  s.add_development_dependency "parser", ">= 2.5", "!= 2.5.1.1"
  s.add_development_dependency "pry-byebug", "3.9.0"
  s.add_development_dependency "rainbow", "2.2.2"
  s.add_development_dependency "rake", "~> 13.0"
  s.add_development_dependency "rspec", "~> 3.0"
  s.add_development_dependency "rubocop-powerhome", "0.5.0"
  s.add_development_dependency "simplecov", "0.15.1"
  s.add_development_dependency "test-unit", "3.1.5"
  s.add_development_dependency "yard", "0.9.21"
end
