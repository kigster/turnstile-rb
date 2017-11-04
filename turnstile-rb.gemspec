# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'turnstile/version'

Gem::Specification.new do |spec|
  spec.name          = 'turnstile-rb'
  spec.version       = Turnstile::VERSION
  spec.authors       = ['Konstantin Gredeskoul']
  spec.email         = %w(kigster@gmail.com)

  spec.summary       = %q{Asynchronous and non-invasive concurrent user tracking with Redis, by scanning application logs across all servers.}

  spec.description   = Turnstile::GEM_DESCRIPTION

  spec.homepage      = 'https://github.com/kigster/turnstile-rb'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/).reject {|f| f =~ /Gemfile/ }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'redis'
  spec.add_dependency 'file-tail'
  spec.add_dependency 'daemons'
  spec.add_dependency 'json'
  spec.add_dependency 'hashie'
  spec.add_dependency 'colored2'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'yard'

  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'simplecov'
end
