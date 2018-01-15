# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'activefacts/version'

Gem::Specification.new do |spec|
  spec.name          = "activefacts"
  spec.version       = ActiveFacts::VERSION
  spec.authors       = ["Clifford Heath"]
  spec.email         = ["clifford.heath@gmail.com"]

  spec.summary = %q{A fact modeling and query language (CQL) and application runtime (the Constellation API)}
  spec.description = %q{
ActiveFacts provides the Constellation Query Language (CQL),
a fact modeling and query language.
CQL combines a controlled natural language verbalisation with formal logic,
producing a formal language that reads like plain English. ActiveFacts compiles
fact models in CQL and generates relational and object models in SQL, Ruby and other languages.
}
  spec.homepage = "http://dataconstellation.com/ActiveFacts/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", ">= 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.3"

  spec.add_runtime_dependency "activefacts-cql", ">= 1.9", "~> 1"
  spec.add_runtime_dependency "activefacts-orm", ">= 1.9", "~> 1"
  spec.add_runtime_dependency "activefacts-generators", ">= 1.9", "~> 1"
end
