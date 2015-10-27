# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'quiz_packager/version'

Gem::Specification.new do |spec|
  spec.name          = "quiz_packager"
  spec.version       = QuizPackager::VERSION
  spec.authors       = ["Tim Ross"]
  spec.email         = ["tim@timross.info"]

  spec.summary       = %q{a private gem for use on pinrose}
  spec.homepage      = "http://www.pinrose.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rubyzip", "~> 1.1.7"

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
end
