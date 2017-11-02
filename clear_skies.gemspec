# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'clear_skies/version'

Gem::Specification.new do |spec|
  spec.name          = "clear_skies"
  spec.version       = ClearSkies::VERSION
  spec.authors       = ["Chris Constantine"]
  spec.email         = ["chris@omadahealth.com"]

  spec.summary       = %q{Cloudwatch metrics for prometheus.}
  spec.description   = %q{A tool for exposing cloudwatch metrics for prometheus.}
  spec.homepage      = "https://github.com/omadahealth/clear_skies"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "puma"
  spec.add_dependency "aws-sdk"
  spec.add_dependency "redis"
  spec.add_dependency "elasticsearch"
  spec.add_dependency "greek_fire", ">= 0.3.0"
  spec.add_dependency "bugsnag-api", ">= 2.0.0"

  spec.add_dependency "awesome_print"

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "docker-api"
end
