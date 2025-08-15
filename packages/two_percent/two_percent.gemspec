# frozen_string_literal: true

require_relative "lib/two_percent/version"

Gem::Specification.new do |spec|
  spec.name        = "two_percent"
  spec.version     = TwoPercent::VERSION
  spec.email       = ["carlos.palhares@powerhrg.com", "katie.weber@powerhrg.com", "dsmith@powerhrg.com"]
  spec.authors     = ["Carlos Palhares", "Katie Edgar", "Dan Smith"]
  spec.homepage    = "https://github.com/powerhome/power-tools"
  spec.summary     = "Adds a thin SCIM interface, and delegates the actions taken on write calls to observers"
  spec.description = spec.summary
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/packages/two_percent/docs/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.metadata["rubygems_mfa_required"] = "true"

  spec.add_dependency "aether_observatory", ">= 1.0.1"
  spec.add_dependency "rails", ">= 6.1"
end
