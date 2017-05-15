# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'clear_skies/version'

Gem::Specification.new do |spec|
  spec.name          = "clear_skies"
  spec.version       = ClearSkies::VERSION
  spec.authors       = ["cconstantine"]
  spec.email         = ["chris@omadahealth.com"]

  spec.summary       = %q{Cloudwatch metrics for prometheus.}
  spec.description   = %q{A tool for exposing cloudwatch metrics for prometheus.}
  spec.homepage      = "https://github.com/omadahealth/clear_skies"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "puma"
  spec.add_dependency "aws-sdk"
  spec.add_dependency "greek_fire", ">= 0.2.1"
  spec.add_dependency "awesome_print"

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
end
