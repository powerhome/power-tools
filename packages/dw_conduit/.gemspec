# frozen_string_literal: true

require_relative "lib/dw_conduit/version"

Gem::Specification.new do |spec|
  spec.name = "dw_conduit"
  spec.version = DWConduit::VERSION
  spec.authors = ["Vinicius Dittgen"]
  spec.email = ["vinipd@gmail.com"]

  spec.summary = "A Ruby connector for data warehouses"
  spec.description = "A flexible data warehouse connector with support for Trino and extensibility for other engines"
  spec.homepage = "https://github.com/powerhome/power-tools"
  spec.required_ruby_version = ">= 3.3.5"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main/packages/dw_conduit"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/packages/dw_conduit/CHANGELOG.md"

  spec.files = Dir["{lib}/**/*", "README.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rest-client", "~> 2.1"

  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "rubocop-powerhome"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "appraisal", "~> 2.5.0"
  spec.add_dependency "sequel", "~> 5.90.0"
  spec.metadata["rubygems_mfa_required"] = "true"
end
