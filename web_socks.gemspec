# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'web_socks/version'

Gem::Specification.new do |spec|
  spec.name          = "web_socks"
  spec.version       = WebSocks::VERSION
  spec.authors       = ["Dan Knox"]
  spec.email         = ["dknox@threedotloft.com"]
  spec.description   = %q{A WebSocket adapter for Rack apps based on the websocket-driver gem.}
  spec.summary       = %q{A WebSocket adapter for Rack apps based on the websocket-driver gem.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "websocket-driver"
  spec.add_dependency "celluloid"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
