# frozen_string_literal: true

require_relative "lib/nitro_config/version"

Gem::Specification.new do |spec|
  spec.name = "nitro_config"
  spec.version = NitroConfig::VERSION
  spec.authors = ["Carlos Palhares", "Jill Klang"]
  spec.email = ["chjunior@gmail.com", "jillian.emilie@gmail.com"]

  spec.summary = "Nitro Configuration Loader"
  spec.description = "Loads Nitro configuration and makes it available to the application"
  spec.homepage = "https://github.com/powerhome/power-tools"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/packages/nitro_config/docs/CHANGELOG.md"

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

  spec.add_dependency "activesupport", ">= 6.0.6.1", "< 7.1"
  spec.add_development_dependency "appraisal", "~> 2.4.1"
  spec.add_development_dependency "combustion", "~> 1.3"
end
