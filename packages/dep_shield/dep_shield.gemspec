# frozen_string_literal: true

require_relative "lib/dep_shield/version"

Gem::Specification.new do |spec|
  spec.name = "dep_shield"
  spec.version = DepShield::VERSION
  spec.authors = ["Jill Klang"]
  spec.email = ["jillian.emilie@powerhrg.com"]

  spec.summary = "Vigilant alerts for deprecated or outdated code."
  spec.description = "Enable alerts about deprecated features & prevent new ones from being introduced."
  spec.homepage = "https://github.com/powerhome/power-tools"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/packages/data_taster/docs/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "appraisal", "~> 2.5.0"
  spec.add_development_dependency "combustion", "~> 1.4"
  spec.add_development_dependency "license_finder", ">= 7.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-rails", "~> 5.1.2"
  spec.add_development_dependency "sqlite3", "~> 1.4.2"

  spec.add_dependency "nitro_config"
  spec.add_dependency "rails", ">= 6.0.6.1", "< 7.0"
  spec.add_dependency "sentry-rails", "5.5.0"
  spec.add_dependency "sentry-ruby", "5.5.0"
end
