#
# ActiveFacts CQL loader.
# Copyright (c) 2007 Clifford Heath. Read the LICENSE file.
#
require 'rubygems'
require 'polyglot'
require 'activefacts/support'
require 'activefacts/input/cql'
require 'activefacts/generate/ruby'

module ActiveFacts
  # Extend the generated parser:
  class CQLLoader
    # This load method for Polyglot tells it how to _require_ a CQL file.
    # The CQL file is parsed to a vocabulary constellation, which is generated
    # to Ruby code and eval'd, making the generated classes available.
    def self.load(file)
      debug "Loading #{file}" do
        vocabulary = ActiveFacts::Input::CQL.readfile(file)

        ruby = StringIO.new
        @dumper = ActiveFacts::Generate::RUBY.new(vocabulary.constellation)
        @dumper.generate(ruby)
        ruby.rewind
        eval ruby.read, ::TOPLEVEL_BINDING
      end
    end
  end

  Polyglot.register('cql', CQLLoader)
end
