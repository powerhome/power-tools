# frozen_string_literal: true

require_relative "lib/edgestitch/version"

Gem::Specification.new do |spec|
  spec.name        = "edgestitch"
  spec.version     = Edgestitch::VERSION
  spec.authors     = ["Carlos Palhares"]
  spec.email       = ["chjunior@gmail.com"]

  spec.description = spec.summary = "Edgestitch allows engines to define partial structure-self.sql files to be " \
                                    "stitched into a single structure.sql file by the umbrella application."
  spec.homepage = "https://github.com/powerhome/power-tools"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/packages/edgestitch/docs/CHANGELOG.md"

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
end
