# frozen_string_literal: true

require_relative "lib/audiences/version"

Gem::Specification.new do |spec|
  spec.name        = "audiences"
  spec.version     = Audiences::VERSION
  spec.authors     = ["Carlos Palhares"]
  spec.email       = ["carlos.palhares@powerhrg.com"]
  spec.homepage    = "https://github.com/powerhome/power-tools"
  spec.summary     = "Audiences system"
  spec.description = "Audiences notify the Rails app when a SCIM backend updates a user affecting matching audiences"
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/packages/audiences/docs/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "docs/*"]
  end

  spec.required_ruby_version = ">= 2.7"
  spec.add_dependency "rails", ">= 6.0"
  spec.metadata["rubygems_mfa_required"] = "true"
end
