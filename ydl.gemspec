# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ydl/version'

Gem::Specification.new do |spec|
  spec.name          = "ydl"
  spec.version       = Ydl::VERSION
  spec.authors       = ["Nikhil Gupta"]
  spec.email         = ["me@nikhgupta.com"]
  spec.description   = %q{A companion to 'youtube-dl', and a local video database.}
  spec.summary       = %q{A companion to 'youtube-dl', and a local video database.}
  spec.homepage      = "http://github.com/nikhgupta/ydl}"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"

  spec.add_dependency 'thor'
  spec.add_dependency 'sequel'
  spec.add_dependency 'sqlite3'
  spec.add_dependency 'blurrily'
  spec.add_dependency 'conjuror'

  spec.add_development_dependency "pry"
  spec.add_development_dependency "aruba"
end
