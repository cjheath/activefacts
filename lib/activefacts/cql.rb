#
# ActiveFacts CQL loader.
# Copyright (c) Clifford Heath 2007.
#
require 'rubygems'
require 'polyglot'
require 'activefacts/cql/parser'

module ActiveFacts
  # Extend the generated parser:
  class CQLLoader

    # The load method required by Polyglot.
    # The meaning of load will probably be to parse the file, and
    # generate and eval Ruby source code for the implied modules.
    def self.load(file)
      debug "Loading #{file}" do
        parser = ActiveFacts::CQLParser.new

        File.open(file) do |f|
          result = parser.parse_all(input = f.read, :definition) { |node|
              parser.definition(node)
              nil
            }
          raise parser.failure_reason unless result
        end
      end
    end
  end

  Polyglot.register('cql', CQLParser)
end
