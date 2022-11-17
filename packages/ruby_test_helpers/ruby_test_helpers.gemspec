# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

Gem::Specification.new do |s|
  s.name        = "ruby_test_helpers"
  s.version     = "0.0.1"
  s.authors     = ['Carlos Palhares', 'Jill Klang']
  s.email       = ['chjunior@gmail.com', 'jillian.emilie@gmail.com']
  s.homepage = 'https://github.com/powerhome/power-tools'
  s.license = 'MIT'
  s.required_ruby_version = '>= 2.7'
  s.summary     = "Helpers for Ruby component tests"
  s.description = "Making testing components easier by encapsulating common helpers and patterns."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile", "docs/README.md"]

  s.add_runtime_dependency "capybara", "2.16"
  s.add_runtime_dependency "capybara-selenium", "0.0.6"
  s.add_runtime_dependency "puma", "5.6.4"
  s.add_runtime_dependency "site_prism", "3.5"
  s.add_runtime_dependency "webdrivers", "4.4.1"

  s.add_development_dependency "activesupport", "5.2.8.1"

  s.add_development_dependency "bundler", "~> 2.1"
  s.add_development_dependency "factory_bot", "~> 4.8"
  s.add_development_dependency "pry-byebug", "3.9.0"
  s.add_development_dependency "rainbow", "2.2.2"
  s.add_development_dependency "rake", "~> 13.0"
  s.add_development_dependency "rspec", "~> 3.0"
  s.add_development_dependency "rubocop-powerhome", "0.5.0"
  s.add_development_dependency "simplecov", "0.15.1"
  s.add_development_dependency "test-unit", "3.1.5"
  s.add_development_dependency "yard", "0.9.21"
end
