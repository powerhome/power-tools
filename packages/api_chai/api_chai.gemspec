# frozen_string_literal: true

require_relative "lib/api_chai/version"

Gem::Specification.new do |spec|
  spec.name = "api_chai"
  spec.version = ApiChai::VERSION
  spec.authors = ["Jill Klang"]
  spec.email = ["jillian.emilie@gmail.com"]

  spec.summary = "net-http simplicity infused with error handling and reporting"
  spec.description = "Serve up smooth API integrations lightly steeped in graceful errors, Sentry & NewRelic reporting."
  spec.homepage = "https://github.com/powerhome/power-tools"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/packages/api_chai/docs/CHANGELOG.md"

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
  spec.add_development_dependency "license_finder", "~> 7.0"
  spec.add_development_dependency "rubocop-powerhome", "0.5.0"
end
