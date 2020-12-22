# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'consent/version'

Gem::Specification.new do |spec|
  spec.name          = 'consent'
  spec.version       = Consent::VERSION
  spec.authors       = ['Carlos Palhares']
  spec.email         = ['chjunior@gmail.com']

  spec.summary       = 'Consent'
  spec.description   = 'Consent'
  
  spec.licenses = ['MIT']

  spec.files = `git ls-files`.split.reject do |file|
    file =~ /^(test|spec|features)/
  end
  spec.require_paths = ['lib']

  spec.add_development_dependency 'activesupport', '>= 4.1.11'
  spec.add_development_dependency 'bundler', '>= 1.17.3'
  spec.add_development_dependency 'cancancan', '~> 1.15.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.65.0'
end
