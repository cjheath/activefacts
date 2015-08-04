#       Compile a CQL string into an ActiveFacts vocabulary.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/cql/parser'
require 'activefacts/cql/compiler/shared'
require 'activefacts/cql/compiler/value_type'
require 'activefacts/cql/compiler/entity_type'
require 'activefacts/cql/compiler/clause'
require 'activefacts/cql/compiler/fact_type'
require 'activefacts/cql/compiler/expression'
require 'activefacts/cql/compiler/fact'
require 'activefacts/cql/compiler/constraint'
require 'activefacts/cql/compiler/query'

module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser
      LANGUAGES = {
        'en' => 'English',
        'fr' => 'French',
        'cn' => 'Mandarin'
      }
      attr_reader :vocabulary

      def initialize *a
        @filename = a.shift || "stdio"
        super *a
        @constellation = ActiveFacts::API::Constellation.new(ActiveFacts::Metamodel)
        @language = nil
        trace :file, "Parsing '#{@filename}'"
      end

      def compile_file filename
        old_filename = @filename
        @filename = filename
        File.open(filename) do |f|
          compile(f.read)
        end
        @filename = old_filename
        @vocabulary
      end

      # Load the appropriate natural language module
      def detect_language
        @filename =~ /.*\.(..)\.cql$/i
        language_code = $1
        @language = LANGUAGES[language_code] || 'English'
      end

      def include_language
        detect_language unless @langage
        require 'activefacts/cql/Language/'+@language
        language_module = ActiveFacts::CQL.const_get(@language)
        extend language_module
      end

      # Mark any new Concepts as belonging to this topic
      def topic_flood
	@constellation.Concept.each do |key, concept|
	  next if concept.topic
	  trace :topic, "Colouring #{concept.describe} with #{@topic.topic_name}"
	  concept.topic = @topic
	end
      end

      def compile input
        include_language

        @string = input

        # The syntax tree created from each parsed CQL statement gets passed to the block.
        # parse_all returns an array of the block's non-nil return values.
        ok = parse_all(@string, :definition) do |node|
          trace :parse, "Parsed '#{node.text_value.gsub(/\s+/,' ').strip}'" do
	    trace :lex, (proc { node.inspect })
            begin
              ast = node.ast
              next unless ast
              trace :ast, ast.inspect
              ast.tree = node
              ast.constellation = @constellation
              ast.vocabulary = @vocabulary
              value = compile_definition ast
              trace :definition, "Compiled to #{value.is_a?(Array) ? value.map{|v| v.verbalise}*', ' : value.verbalise}" if value
	      if value.is_a?(ActiveFacts::Metamodel::Topic)
		topic_flood if @topic
		@topic = value
	      elsif ast.is_a?(Compiler::Vocabulary)
		topic_flood if @topic
		@vocabulary = value
		@topic = @constellation.Topic(@vocabulary.name)
	      end
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
	  topic_flood if @topic
        end
        raise failure_reason unless ok
        vocabulary
      end

      def compile_import file, aliases
        saved_index = @index
        saved_block = @block
        saved_string = @string
        saved_input_length = @input_length
        saved_topic = @topic
        old_filename = @filename
        @filename = File.dirname(old_filename)+'/'+file+'.cql'

        # REVISIT: Save and use another @vocabulary for this file?
        File.open(@filename) do |f|
	  topic_flood if @topic
	  @topic = @constellation.Topic(File.basename(@filename, '.cql'))
	  trace :import, "Importing #{@filename} as #{@topic.topic_name}" do
	    ok = parse_all(f.read, nil, &@block)
	  end
	  @topic = saved_topic
        end

      rescue => e
        ne = StandardError.new("In #{@filename} #{e.message.strip}")
        ne.set_backtrace(e.backtrace)
        raise ne
      ensure
        @block = saved_block
        @index = saved_index
        @input_length = saved_input_length
        @string = saved_string
        @filename = old_filename
        nil
      end

      def compile_definition ast
        ast.compile
      end

      def unit? s
        name = @constellation.Name[s]
        units = (!name ? [] : Array(name.unit) + Array(name.plural_named_unit)).uniq
        trace :units, "Looking for unit #{s}, got #{units.map{|u|u.name}.inspect}"
        units.size > 0
      end

    end
  end
end
