# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'debloater/version'

Gem::Specification.new do |spec|
  spec.name          = 'debloater'
  spec.version       = Debloater::VERSION
  spec.authors       = ['Julien Letessier']
  spec.email         = ['julien.letessier@gmail.com']

  spec.summary       = %q{Safely rebuilds bloated PostgreSQL indices}
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/deliveroo/debloater'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'pry'

  spec.add_runtime_dependency 'pg'
end
