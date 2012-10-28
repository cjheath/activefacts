module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser

      # In a declaration, a Variable has one or more VarRef's.
      # A Variable is for a single ObjectType, normally related to just one Role,
      # and the references (VarRefs) to it will normally be the object_type name
      # with the same adjectives (modulo loose binding),
      # or a role name or subscript reference.
      #
      # In some situations a Variable will have some VarRefs with the same adjectives,
      # and one or more VarRefs with no adjectives - this is called "loose binding".
      class Variable
        attr_reader :player             # The ObjectType (object type)
        attr_reader :refs               # an array of the VarRefs
        attr_reader :role_name
        attr_accessor :rebound_to       # Loose binding may set this to another variable
        attr_accessor :join_node
        attr_accessor :instance         # When binding fact instances, the instance goes here

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
        attr_accessor :vocabulary
        attr_accessor :allowed_forward_terms
        attr_accessor :left_contraction_allowed
        attr_accessor :left_contractable_clause
        attr_accessor :left_contraction_conjunction
        attr_reader :variables             # The Variables in this declaration
        attr_reader :player_by_role_name

        def initialize vocabulary
          @vocabulary = vocabulary
          @vocabulary_identifier = @vocabulary.identifying_role_values
          @allowed_forward_terms = []
          @variables = {}
          @player_by_role_name = {}
          @left_contraction_allowed = false
        end

        # Look up this object_type by its name
        def object_type(name)
          constellation = @vocabulary.constellation
          player = constellation.ObjectType[[@vocabulary_identifier, name]]

          # Bind to an existing role which has a role name (that's why we bind those first)
          player ||= @player_by_role_name[name]

          if !player && @allowed_forward_terms.include?(name)
            player = constellation.EntityType(@vocabulary, name)
          end

          player
        end

        # Pass in an array of clauses or VarRefs for player identification and binding (creating the Variables)
        # It's necessary to identify all players that define a role name first,
        # so those names exist in the context for where they're used.
        def bind *clauses
          cl = clauses.flatten
          cl.each { |clause| clause.identify_players_with_role_name(self) }
          cl.each { |clause| clause.identify_other_players(self) }
          cl.each { |clause| clause.bind(self) }
        end
      end

      class Definition
        attr_accessor :constellation, :vocabulary, :tree
        def compile
          raise "#{self.class} should implement the compile method"
        end

        def to_s
          @vocabulary ? "#{vocabulary.to_s}::" : ''
        end

        def source
          @tree.text_value
        end
      end

      class Vocabulary < Definition
        def initialize name
          @name = name
        end

        def compile
          @constellation.Vocabulary @name
        end

        def to_s
          @name
        end
      end

      class Import < Definition
        def initialize parser, name, alias_hash
          @parser = parser
          @name = name
          @alias_hash = alias_hash
        end

        def to_s
          "#{@vocabulary.to_s} imports #{@alias_hash.map{|k,v| "#{k} as #{v}" }*', '};"
        end

        def compile
          @parser.compile_import(@name, @alias_hash)
        end
      end

      class ObjectType < Definition
        attr_reader :name

        def initialize name
          @name = name
        end

        def to_s
          "#{super}#{@name}"
        end
      end

    end
  end
end
