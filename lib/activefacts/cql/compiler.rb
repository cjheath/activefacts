#       Compile a CQL string into an ActiveFacts vocabulary.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/cql/parser'

require 'activefacts/cql/compiler/shared'
require 'activefacts/cql/compiler/value_type'
require 'activefacts/cql/compiler/entity_type'
require 'activefacts/cql/compiler/reading'
require 'activefacts/cql/compiler/fact_type'
require 'activefacts/cql/compiler/fact'
require 'activefacts/cql/compiler/constraint'

module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser
      attr_reader :vocabulary

      def initialize(filename = "stdin")
        @filename = filename
        @constellation = ActiveFacts::API::Constellation.new(ActiveFacts::Metamodel)
      end

      def compile input
        @string = input
        # The syntax tree created from each parsed CQL statement gets passed to the block.
        # parse_all returns an array of the block's non-nil return values.
        ok = parse_all(@string, :definition) do |node|
          debug :parse, "Parsed '#{node.text_value.gsub(/\s+/,' ').strip}'" do
            begin
              ast = node.ast
              debug :ast, ast.inspect
              ast.source = node.body
              ast.constellation = @constellation
              ast.vocabulary = @vocabulary
              value = compile_definition ast
              @vocabulary = value if ast.is_a?(Compiler::Vocabulary)
            rescue => e
              # Augment the exception message, but preserve the backtrace
              start_line = @string.line_of(node.interval.first)
              end_line = @string.line_of(node.interval.last-1)
              lines = start_line != end_line ? "s #{start_line}-#{end_line}" : " #{start_line.to_s}"
              ne = StandardError.new("at line#{lines} #{e.message.strip}")
              ne.set_backtrace(e.backtrace)
              raise ne
            end
          end
        end
        raise failure_reason unless ok
        vocabulary
      end

      def compile_definition ast
        ast.compile
      end

    end
  end
end
