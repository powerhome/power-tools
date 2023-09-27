# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ostruct/sanitizer/version'

Gem::Specification.new do |spec|
  spec.name          = "ostruct-sanitizer"
  spec.version       = OStruct::Sanitizer::VERSION
  spec.authors       = ["Diego Borges"]
  spec.email         = ["drborges.cic@gmail.com"]

  spec.summary       = %q{Provides Rails-like sanitization rules for OpenStruct fields.}
  spec.description   = %q{Provides Rails-like sanitization rules for OpenStruct fields.}
  spec.homepage      = "https://github.com/powerhome/ostruct-sanitizer"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.6'

  spec.add_development_dependency "bundler", "~> 2.4.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "byebug"
end
