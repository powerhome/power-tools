# frozen_string_literal: true

require_relative "lib/data_taster/version"

Gem::Specification.new do |spec|
  spec.name = "data_taster"
  spec.version = DataTaster::VERSION
  spec.authors = ["Jill Klang"]
  spec.email = ["jillian.emilie@gmail.com"]

  spec.summary = "Delicious and sanitized data samples for development and testing."
  spec.description = "DataTaster allows applications to introduce configuration for which tables, rows, and columns they want to include for their development processes. The data is exported, sanitized, and then imported all with the help of DataTaster."
  spec.homepage = "https://github.com/powerhome/power-tools"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/packages/data_taster/docs/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
