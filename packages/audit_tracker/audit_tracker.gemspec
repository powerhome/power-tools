# frozen_string_literal: true

require_relative "lib/audit_tracker/version"

Gem::Specification.new do |spec|
  spec.name = "audit_tracker"
  spec.version = AuditTracker::VERSION
  spec.authors = ["Carlos Palhares"]
  spec.email = ["chjunior@gmail.com"]

  spec.summary = "AuditTracker helps you centralize data tracking configuration to be used across different models"
  spec.description = spec.summary
  spec.homepage = "https://github.com/powerhome/power-tools"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/packages/audit_tracker/docs/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "activerecord", ">= 6.0.6.1", "< 7.1"
  spec.add_development_dependency "appraisal", "~> 2.4.1"
  spec.add_development_dependency "combustion", "~> 1.3"
  spec.add_development_dependency "rspec-rails", "~> 5.1.2"
  spec.add_development_dependency "shoulda-matchers", "~> 5.1.0"
  spec.add_development_dependency "sqlite3", "~> 1.4.2"
end
