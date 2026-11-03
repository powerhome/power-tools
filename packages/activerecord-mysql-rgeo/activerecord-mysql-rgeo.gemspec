# frozen_string_literal: true

require_relative "lib/active_record/mysql_rgeo/version"

Gem::Specification.new do |spec|
  spec.name = "activerecord-mysql-rgeo"
  spec.version = ActiveRecord::MysqlRgeo::VERSION
  spec.authors = ["Carlos Palhares"]
  spec.email = ["carlos.palhares@powerhrg.com"]

  spec.summary = "RGeo spatial support for Rails' own MySQL adapters (trilogy and mysql2)"
  spec.description = "Extends Active Record's built-in MySQL adapters (trilogy and mysql2) with spatial types, " \
                     "migrations and queries backed by RGeo. A drop-in replacement for activerecord-mysql2rgeo-adapter."
  spec.homepage = "https://github.com/powerhome/power-tools"
  spec.license = "BSD-3-Clause"
  spec.required_ruby_version = ">= 3.3"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/packages/activerecord-mysql-rgeo/docs/CHANGELOG.md"

  spec.files = Dir["lib/**/*", "LICENSE.txt", "docs/README.md", "docs/CHANGELOG.md"]
  spec.require_paths = ["lib"]

  # The MySQL driver (trilogy or mysql2) is intentionally not a dependency:
  # applications bring the one they use, as with Rails' own adapters.
  spec.add_dependency "activerecord", ">= 7.2"
  spec.add_dependency "rgeo-activerecord", ">= 8.0"

  spec.add_development_dependency "appraisal", "~> 2.5.0"
  spec.add_development_dependency "license_finder", "~> 7.0"
end
