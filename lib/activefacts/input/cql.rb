#
# Compile a CQL file into an ActiveFacts vocabulary.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/cql/parser'

module ActiveFacts
  module Input
    class CQL
      # Open the specified file and read it:
      def self.readfile(filename)
        File.open(filename) {|file|
          self.read(file, filename)
        }
      end

      # Read the specified input stream:
      def self.read(file, filename = "stdin")
        CQL.new(file.read, filename).read
      end 

      def initialize(file, filename = "stdin")
        @file = file
        @filename = filename
      end

      # Read the input, returning a new Vocabulary:
      def read
        @constellation = Constellation.new(ActiveFacts::Metamodel)

        @parser = ActiveFacts::CQLParser.new

        # The syntax tree created from each parsed CQL statement gets passed to the block.
        # parse_all returns an array of the block's non-nil return values.
        result = @parser.parse_all(@file, :definition) { |node|
            kind, *value = @parser.definition(node)
            case kind
            when :vocabulary
              @vocabulary = @constellation.Vocabulary(value[0], nil)
            when :data_type
              value_type *value
            when :entity_type
              entity_type *value
            when :fact_type
              fact_type *value
            else
              print "="*20+" unhandled declaration type: "; p kind
            end

            nil
          }
        raise parser.failure_reason unless result
        @vocabulary
        end

      def value_type(name, base_type, parameters, unit, ranges)
        length, scale = *parameters

        # Create the base type:
        base = base_type == name ? nil : @constellation.ValueType(base_type, @vocabulary)

        # Create and initialise the ValueType:
        vt = @constellation.ValueType(name, @vocabulary)
        vt.supertype = base
        vt.length = length if length
        vt.scale = scale if scale

        if ranges.size != 0
          vt.value_restriction = @constellation.ValueRestriction(:new)
          ranges.each do |range|
            #v_range = value_range(range)
            min, max = *range
            v_range = @constellation.ValueRange(
              min ? [min.to_s, true] : nil,
              max ? [max.to_s, true] : nil
              )
            ar = @constellation.AllowedRange(v_range, vt.value_restriction)
          end
        end
      end

      def entity_type(name, supertypes, identification, clauses)
        et = @constellation.EntityType(name, @vocabulary)

        # Set up the supertypes:
        supertypes.each do |supertype|
          supertype = @constellation.EntityType(supertype, @vocabulary)
          inheritance_fact = @constellation.TypeInheritance(et, supertype)
          inheritance_fact.provides_identification = true if !identification && supertype == supertypes[0]
        end

        # REVISIT: The identification roles will be defined in the clauses.

        # REVISIT: Process the entity type clauses (fact type readings)
      end

      def fact_type(name, readings, clauses) 
        ft = @constellation.FactType(:new)

        # The fact type has a name iff it's objectified as an entity type
        ft.entity_type = @constellation.EntityType(name, @vocabulary) if name

        readings.each do |reading|
          junk, qualifiers, phrases = *reading
          print "REVISIT Fact readings: "; p [ qualifiers, phrases ]
        end

        # REVISIT: Process the fact derivation clauses, if any
      end

    end
  end
end
