module ActiveFacts
  module CQL
    class Compiler

      # An Operation is a binary or ternary fact type involving an operator,
      # a result, and one or two operands.
      # Viewed as a result, it behaves like a Reference with a nested Clause.
      # Viewed as a fact type, it behaves like a Clause.
      #
      # The only exception here is an equality comparison, where it may
      # turn out that the equality is merely a projection. In this case
      # the Operation is dropped from the clauses and is replaced by the
      # projected operand.
      #
      # Each operand may be a Literal, a Reference, or another Operation,
      # so we need to recurse down the tree to build the query.
      #
      class Operation
        # Reference (in)compatibility:
        [ :term, :leading_adjective, :trailing_adjective, :role_name, :quantifier,
          :value_constraint, :embedded_presence_constraint, :literal
        ].each do |s|
          define_method(s) { raise "Unexpected call to Operation\##{s}" }
          define_method(:"#{s}=") { raise "Unexpected call to Operation\##{s}=" }
        end
        def role_name; nil; end
        def leading_adjective; nil; end
        def trailing_adjective; nil; end
        def value_constraint; nil; end
        def literal; nil; end
	def side_effects; nil; end
        attr_accessor :player     # What ObjectType does the Binding denote
        attr_accessor :binding    # What Binding for that ObjectType
        attr_accessor :clause     # What clause does the result participate in?
        attr_accessor :role       # Which Role of this ObjectType
        attr_accessor :role_ref   # Which RoleRef to that Role
        attr_accessor :certainty  # nil, true, false -> maybe, definitely, not
        def nested_clauses; @nested_clauses ||= [self]; end
        def clause; self; end
        def objectification_of; @fact_type; end
        # Clause (in)compatibility:
        [ :phrases, :qualifiers, :context_note, :reading, :role_sequence, :fact
        ].each do |s|
          define_method(s) { raise "Unexpected call to Operation\##{s}" }
          define_method(:"#{s}=") { raise "Unexpected call to Operation\##{s}=" }
        end
        def conjunction; nil; end
        attr_reader :fact_type
        def objectified_as; self; end   # The Reference which objectified this fact type

	def initialize
	  @certainty = true	  # Assume it's definite
	end

        def operands context = nil
          raise "REVISIT: Implement operand enumeration in the operator subclass #{self.class.name}"
        end

        def identify_players_with_role_name context
          # Just recurse, there's no way (yet: REVISIT?) to add a role name to the result of an expression
          refs.each { |o|
            o.identify_players_with_role_name(context)
          }
          # As yet, an operation cannot have a role name:
          # identify_player context if role_name
        end

        def identify_other_players context
          # Just recurse, there's no way (yet: REVISIT?) to add a role name to the result of an expression
          refs.each { |o|
            o.identify_other_players(context)
          }
          identify_player context
        end

        def bind context
          refs.each do |o|
            o.bind context
          end
          name = result_type_name(context)
          @player = result_value_type(context, name)
          key = "#{name} #{object_id}"  # Every Operation result is a unique Binding
          @binding = (context.bindings[key] ||= Binding.new(@player))
          @binding.refs << self
          @binding
        end

        def result_type_name(context)
          raise "REVISIT: Implement result_type_name in the #{self.class.name} subclass"
        end

        def result_value_type(context, name)
          vocabulary = context.vocabulary
          constellation = vocabulary.constellation
	  vocabulary.valid_value_type_name(name) ||
	    constellation.ValueType(vocabulary, name, :concept => :new)
        end

        def is_naked_object_type
          false # All Operations are non-naked
        end

        def match_existing_fact_type context
          opnds = refs
          result_ref = Reference.new(@binding.player.name)
          result_ref.player = @binding.player
          result_ref.binding = @binding
          @binding.refs << result_ref
          clause_ast = Clause.new(
            [result_ref, '='] +
              (opnds.size > 1 ? [opnds[0]] : []) +
              [operator, opnds[-1]]
          )

          # REVISIT: All operands must be value-types or simply-identified Entity Types.

          # REVISIT: We should auto-create steps from Entity Types to an identifying ValueType
          # REVISIT: We should traverse up the supertype of ValueTypes to find a DataType
          @fact_type = clause_ast.match_existing_fact_type(context, :exact_type => true)
	  if clause.certainty == false
	    raise "Negated fact types in expressions are not yet supported: #{clause.inspect}"
	  end
          return @fact_type if @fact_type

          @fact_type = clause_ast.make_fact_type context.vocabulary
          reading = clause_ast.make_reading context.vocabulary, @fact_type
          rrs = reading.role_sequence.all_role_ref_in_order
          opnds[0].role_ref = rrs[0]
          opnds[-1].role_ref = rrs[-1]
          opnds.each do |opnd|
            next unless opnd.is_a?(Operation)
            opnd.match_existing_fact_type context
	    if opnd.certainty == false
	      raise "Negated fact types in expressions are not yet supported: #{opnd.inspect}"
	    end
          end
          @fact_type
        end

        def is_equality_comparison
          false
        end

        def operator
          raise "REVISIT: Implement operator access in the operator subclass #{self.class.name}"
        end

      end

      class Comparison < Operation
        attr_accessor :operator, :e1, :e2, :qualifiers, :conjunction

        def initialize operator, e1, e2, certainty = true
          @operator, @e1, @e2, @certainty, @qualifiers = operator, e1, e2, certainty, []
        end

        def refs
          [@e1, @e2]
        end

        def bind context
          refs.each do |o|
            o.bind context
          end

          # REVISIT: Return the projected binding instead:
          return @result = nil if @projection

          name = 'Boolean'
          @player = result_value_type(context, name)
          key = "#{name} #{object_id}"  # Every Comparison result is a unique Binding
          @binding = (context.bindings[key] ||= Binding.new(@player))
          @binding.refs << self
          @binding
        end

        def result_type_name(context)
          "COMPARE#{operator}<#{[@e1,@e2].map{|e| e.player.name}*' WITH '})>"
        end

        def is_equality_comparison
          @operator == '='
        end

        def identify_player context
          @player || begin
            if @projection
              raise "REVISIT: The player is the projected expression"
            end
            v = context.vocabulary
            @boolean ||=
	      v.constellation.ValueType[[[v.name], 'Boolean']] ||
	      v.constellation.ValueType(v, 'Boolean', :concept => :new)
            @player = @boolean
          end
        end

=begin
        def project lr
          @projection = lr
          projected_rr = lr == :left ? @e2 : @e1
          true
        end
=end

        def inspect; to_s; end

        def to_s
          "COMPARE#{
	    operator
	  }(#{
	    case @certainty
	    when nil; 'maybe '
	    when false; 'negated '
	    # else 'definitely '
	    end
          }#{
	    e1.to_s
	  } WITH #{
	    e2.to_s
	  }#{
	    @qualifiers.empty? ? '' : ', ['+@qualifiers*', '+']'
	  })"
        end
      end

      class Sum < Operation
        attr_accessor :terms
        def initialize *terms
          @terms = terms
        end

        def refs
          @terms
        end

        def operator
          '+'
        end

        def identify_player context
          @player || begin
            # The players in the @terms have already been identified
            # REVISIT: Check compliance of all units in @terms, and apply conversions where necessary
            # REVISIT: The type of this result should be derived from type promotion rules. Here, we take the left-most.
            # REVISIT: We should define a subtype of the result type here, and apply the units to it.
            v = context.vocabulary
            @player = @terms[0].player
            @player
          end
        end

        def result_type_name(context)
          "SUM_OF<#{ @terms.map{|f| f.player.name}*', ' }>"
        end

=begin
        def result_value_type(context, name)
          # REVISIT: If there are units involved, check compatibility
          vt = super
          vt
        end
=end

        def inspect; to_s; end

        def to_s
          'SUM(' + @terms.map{|term| "#{term.to_s}" } * ' PLUS ' + ')'
        end
      end

      class Product < Operation
        attr_accessor :factors
        def initialize *factors
          @factors = factors
        end

        def refs
          @factors
        end

        def operator
          '*'
        end

        def identify_player context
          @player || begin
            # The players in the @factors have already been identified
            # REVISIT: Calculate the units of the result from the units in @factors
            # REVISIT: The type of this result should be derived from type promotion rules. Here, we take the left-most.
            # REVISIT: We should define a subtype of the result type here, and apply the units to it.
            v = context.vocabulary
            @player = @factors[0].player
          end
        end

        def result_type_name(context)
          "PRODUCT_OF<#{ @factors.map{|f| f.player.name}*' ' }>"
        end

=begin
        def result_value_type(context, name)
          vt = super
          # REVISIT: If there are units involved, create the result units
          vt
        end
=end

        def inspect; to_s; end

        def to_s
          'PRODUCT(' + @factors.map{|factor| "#{factor.to_s}" } * ' TIMES ' + ')'
        end
      end

      class Reciprocal < Operation
        attr_accessor :divisor
        def initialize divisor
          @divisor = divisor
        end

        def operator
          '1/'
        end

        def refs
          [@divisor]
        end

        def identify_player context
          @player || begin
            # The player in @divisor has already been identified
            # REVISIT: Calculate the units of the result from the units in @divisor
            # REVISIT: Do we want integer division?
            v = context.vocabulary
            @player = v.constellation.ValueType(v, 'Real', :concept => :new)
          end
        end

=begin
        def result_type_name(context)
          raise hell
        end
=end

        def inspect; to_s; end

        def to_s
          "RECIPROCAL(#{factor.to_s})"
        end
      end

      class Negate
        attr_accessor :term
        def initialize term
          @term = term
        end

        def operator
          '0-'
        end

        def identify_player context
          @player || begin
            # The player in @term have already been identified
            v = context.vocabulary
            @player = @term.player
          end
        end

=begin
        def result_type_name(context)
          raise hell
        end
=end

        def inspect; to_s; end

        def to_s
          "NEGATIVE(#{term.to_s})"
        end
      end

      class Literal
        attr_accessor :literal, :unit, :role, :role_ref, :clause
        attr_reader :objectification_of, :leading_adjective, :trailing_adjective, :value_constraint

        def initialize literal, unit
          @literal, @unit = literal, unit
        end

        # Stubs:
        def role_name; nil; end
        def nested_clauses; nil; end

        def inspect; to_s; end

        def to_s
          unit ? "(#{@literal.to_s} in #{unit.to_s})" : @literal.to_s
        end

        def player
          @player
        end

        def identify_players_with_role_name(context)
          # Nothing to do here, move along
        end

        def identify_other_players(context)
          identify_player context
        end

        def identify_player context
          @player || begin
            player_name =
              case @literal
              when String; 'String'
              when Float; 'Real'
              when Numeric; 'Integer'
              when TrueClass, FalseClass; 'Boolean'
              end
            v = context.vocabulary
            @player = v.constellation.ValueType(v, player_name)
          end
        end

        def bind context
          @binding || begin
            key = "#{@player.name} #{@literal}"
            @binding = (context.bindings[key] ||= Binding.new(@player))
            @binding.refs << self
          end
        end

        def binding
          @binding
        end
      end

    end
  end
end
