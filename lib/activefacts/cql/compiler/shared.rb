module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser

      # In a declaration, a Binding has one or more RoleRef's.
      # A Binding is for a single Concept, normally related to just one Role,
      # and the references (RoleRefs) to it will normally be the concept name
      # with the same adjectives (modulo loose binding),
      # or a role name or subscript reference.
      #
      # In some situations a Binding will have some RoleRefs with the same adjectives,
      # and one or more RoleRefs with no adjectives - this is called "loose binding".
      class Binding
        attr_reader :player   # The Concept (object type)
        attr_reader :refs     # an array of the RoleRefs
        attr_reader :role_name
        attr_accessor :rebound_to   # Loose binding may set this to another binding

        def initialize player, role_name = nil
          @player = player
          @role_name = role_name
          @refs = []
        end

        def inspect
          "#{@player.name}#{@role_name and @role_name.is_a?(Integer) ? " (#{@role_name})" : " (as #{@role_name})"}"
        end

        def key
          "#{@player.name}#{@role_name && " (as #{@role_name})"}"
        end

        def <=>(other)
          key <=> other.key
        end
      end

      class CompilationContext
        attr_accessor :allowed_forward_terms
        attr_reader :bindings             # The Bindings in this declaration
        attr_reader :player_by_role_name

        def initialize vocabulary
          @vocabulary = vocabulary
          @vocabulary_identifier = @vocabulary.identifying_role_values
          @allowed_forward_terms = []
          @bindings = {}
          @player_by_role_name = {}
        end

        # Look up this concept by its name
        def concept(name)
          constellation = @vocabulary.constellation
          player = constellation.Concept[[@vocabulary_identifier, name]]

          # Bind to an existing role which has a role name (that's why we bind those first)
          player ||= @player_by_role_name[name]

=begin
          # REVISIT: Hack to allow facts to refer to standard types that will be imported from standard vocabulary:
          if !player && %w{Date DateAndTime Time}.include?(name)
            player = constellation.ValueType(virv, name)
          end
=end

          if !player && @allowed_forward_terms.include?(name)
            player = constellation.EntityType(@vocabulary, name)
          end

          player
        end
      end

      class Definition
        attr_accessor :constellation, :vocabulary, :source
        def compile
          raise "#{self.class} should implement the compile method"
        end
      end

      class Vocabulary < Definition
        def initialize name
          @name = name
        end

        def compile
          @constellation.Vocabulary @name
        end
      end

      class Import < Definition
        def initialize name, alias_list
          @name = name
          @alias_list = alias_list
        end
      end

      class Concept < Definition
        attr_reader :name

        def initialize name
          @name = name
        end
      end

    end
  end
end

require 'activefacts/cql/compiler/value_type'
require 'activefacts/cql/compiler/entity_type'
require 'activefacts/cql/compiler/reading'
require 'activefacts/cql/compiler/fact_type'
require 'activefacts/cql/compiler/fact'
require 'activefacts/cql/compiler/constraint'
