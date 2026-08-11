# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'featureflow/version'

Gem::Specification.new do |spec|
  spec.name          = "featureflow"
  spec.version       = Featureflow::VERSION
  spec.authors       = ["Oliver Oldfield-Hodge"]
  spec.email         = ["contact@featureflow.io"]

  spec.summary       = "Ruby SDK for Featureflow"
  spec.description   = "Connects your server with Featureflow. Create features at https://featureflow.io."
  spec.homepage      = "https://github.com/featureflow/featureflow-ruby-sdk"
  spec.license       = "Apache-2.0"

  spec.metadata      = {
    "homepage_uri"    => spec.homepage,
    "source_code_uri" => spec.homepage,
    "changelog_uri"   => "#{spec.homepage}/blob/master/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues"
  }

  # excon ~> 1.5 requires Ruby >= 3.1; declaring it here keeps bundler from
  # offering this version to older rubies and then failing on the dependency.
  spec.required_ruby_version = ">= 3.1"

  spec.files         = Dir["lib/**/*.rb"] + %w[README.md CHANGELOG.md LICENSE]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "cucumber", "~> 11.0"
  spec.add_development_dependency "webrick", "~> 1.8"
  spec.add_development_dependency "debug", "~> 1.9"
  spec.add_dependency "excon", "~> 1.5"
end
