# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nitro/consent/version'

Gem::Specification.new do |spec|
  spec.name          = 'nitro-consent'
  spec.version       = Nitro::Consent::VERSION
  spec.authors       = ['Carlos Palhares']
  spec.email         = ['chjunior@gmail.com']

  spec.summary       = 'Consent'
  spec.description   = 'Consent'

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'http://gems.powerhrg.com'
  end

  spec.files = `git ls-files`.split.reject do |file|
    file =~ /^(test|spec|features)/
  end
  spec.require_paths = ['lib']

  spec.add_development_dependency 'activesupport', '~> 3.2.22'
  spec.add_development_dependency 'cancancan', '~> 1.15.0'
  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
