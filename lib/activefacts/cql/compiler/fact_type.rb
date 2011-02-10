module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser

      class Query < ObjectType  # A fact type which is objectified (whether derived or not) is also an ObjectType
        attr_reader :context    # Exposed for testing purposes
        attr_reader :conditions

        def initialize name, conditions = nil, returning = nil
          super name
          @conditions = conditions
          @returning = returning
        end

        def prepare_roles clauses = nil
          @context ||= CompilationContext.new(@vocabulary)
          clauses = (clauses || []) + @conditions
          clauses.each{ |clause| clause.identify_players_with_role_name(@context) }
          clauses.each{ |clause| clause.identify_other_players(@context) }
          # REVISIT: identify and bind players in @returning clauses also.
          clauses.each{ |clause| clause.bind_roles @context }  # Create the Compiler::Bindings
        end

        def compile
          # Match roles with players, and match clauses with existing fact types
          prepare_roles unless @context

          @context.left_contraction_allowed = true
          match_condition_fact_types

          # Build the join:
          unless @conditions.empty? and !@returning
            @join = build_join_nodes(@conditions.flatten)
            @roles_by_binding = build_all_join_steps(@conditions)
            @join.validate
            @join
          end
          @context.left_contraction_allowed = false
          @join
        end

        def match_condition_fact_types
          @conditions.each do |condition|
            next if condition.is_naked_object_type
            # REVISIT: Many conditions will imply a number of differnt join steps, which need to be handled (similar to objectification joins).
            fact_type = condition.match_existing_fact_type @context
            raise "Unrecognised fact type #{condition.inspect} in #{self.class}" unless fact_type
          end
        end
      end

      class FactType < ActiveFacts::CQL::Compiler::Query
        attr_reader :fact_type
        attr_reader :clauses
        attr_writer :name
        attr_writer :pragmas

        def initialize name, clauses, conditions = nil, returning = nil
          super name, conditions, returning
          @clauses = clauses
        end

        def compile
          # Process:
          # * Identify all role players (must be done for both clauses and conditions BEFORE matching clauses)
          # * Match up the players in all @clauses
          #   - Be aware of multiple roles with the same player, and bind tight/loose using subscripts/role_names/adjectives
          #   - Reject the fact type unless all @clauses match
          # * Find any existing fact type that matches any clause, or make a new one
          # * Add each clause that doesn't already exist in the fact type
          # * Create any ring constraint(s)
          # * Create embedded presence constraints
          # * If fact type has no identifier, arrange to create the implicit one (before first use?)
          # * Objectify the fact type if @name
          #

          prepare_roles @clauses

          # REVISIT: Compiling the conditions here make it impossible to define a self-referential (transitive) query.
          return super if @clauses.empty?  # It's a query

          # Ignore any useless clauses:
          @clauses.reject!{|clause| clause.is_existential_type }
          return true unless @clauses.size > 0   # Nothing interesting was said.

          # See if any existing fact type is being invoked (presumably to objectify or extend it)
          @fact_type = check_compatibility_of_matched_clauses

          verify_matching_roles   # All clauses of a fact type must have the same roles

          if !@fact_type
            # Make a new fact type:
            first_clause = @clauses[0]
            @fact_type = first_clause.make_fact_type(@vocabulary)
            first_clause.make_reading(@vocabulary, @fact_type)
            first_clause.make_embedded_constraints vocabulary
            @fact_type.create_implicit_fact_type_for_unary if @fact_type.all_role.size == 1 && !@name
            @existing_clauses = [first_clause]
          elsif (n = @clauses.size - @existing_clauses.size) > 0
            debug :binding, "Extending existing fact type with #{n} new readings"
          end

          # Now make any new readings:
          new_clauses = @clauses - @existing_clauses
          new_clauses.each do |clause|
            clause.make_reading(@vocabulary, @fact_type)
            clause.make_embedded_constraints vocabulary
          end

          # If a clause matched but the match left extra adjectives, we need to make a new RoleSequence for them:
          @existing_clauses.each do |clause|
            clause.adjust_for_match
            # Add any new constraints that we found in the match (presence, ring, etc)
            clause.make_embedded_constraints(vocabulary)
          end

          # Objectify the fact type if necessary:
          if @name
            if @fact_type.entity_type and @name != @fact_type.entity_type.name
              raise "Cannot objectify fact type as #{@name} and as #{@fact_type.entity_type.name}"
            end
            e = @constellation.EntityType(@vocabulary, @name, :fact_type => @fact_type)
            e.create_implicit_fact_types
            if @pragmas
              e.is_independent = true if @pragmas.delete('independent')
            end
            if @pragmas && @pragmas.size > 0
              $stderr.puts "Mapping pragmas #{@pragmas.inspect} are ignored for objectified fact type #{@name}"
            end
          end

          @clauses.each do |clause|
            next unless clause.context_note
            clause.context_note.compile(@constellation, @fact_type)
          end

          # REVISIT: This isn't the thing to do long term; it needs to be added later only if we find no other constraint
          make_default_identifier_for_fact_type if @conditions.empty?

          # Compile the conditions:
          super
          unless @conditions.empty?
            @clauses.each do |clause|
              project_clause_roles(clause)
            end
          end

          @fact_type
        end

        def project_clause_roles(clause)
          # Attach the clause's role references to the projected roles of the join
          clause.role_refs.each_with_index do |rr, i|
            role, join_role = @roles_by_binding[rr.binding]
            raise "#{rr} must be a role projected from the conditions" unless role
            raise "#{rr} has already-projected join role!" if join_role.role_ref
            rr.role_ref.join_role = join_role
          end
        end

        def check_compatibility_of_matched_clauses
          # REVISIT: If we have conditions, we must match all given clauses exactly (no side-effects)
          @existing_clauses = @clauses.
            select{ |clause| clause.match_existing_fact_type @context }.
            sort_by{ |clause| clause.side_effects.cost }
          fact_types = @existing_clauses.map{ |clause| clause.fact_type }.uniq.compact
          return nil if fact_types.empty?
          # If there's only a single clause, the match must be exact:
          return nil if @clauses.size == 1 && @existing_clauses[0].side_effects.cost != 0
          if (fact_types.size > 1)
            # There must be only one fact type with exact matches:
            if @existing_clauses[0].side_effects.cost != 0 or
              @existing_clauses.detect{|r| r.fact_type != fact_types[0] && r.side_effects.cost == 0 }
              raise "Clauses match different existing fact types '#{fact_types.map{|ft| ft.preferred_reading.expand}*"', '"}'"
            end
            # Try to make false-matched clauses match the chosen one instead
            @existing_clauses.reject!{|r| r.fact_type != fact_types[0] }
          end
          fact_types[0]
        end

        def make_default_identifier_for_fact_type(prefer = true)
          # Non-objectified unaries don't need a PI:
          return if @fact_type.all_role.size == 1 && !@fact_type.entity_type

          # It's possible that this fact type is objectified and inherits identification through a supertype.
          return if @fact_type.entity_type and @fact_type.entity_type.all_type_inheritance_as_subtype.detect{|ti| ti.provides_identification}

          # If it's a non-objectified binary and there's an alethic uniqueness constraint over the fact type already, we're done
          return if !@fact_type.entity_type &&
            @fact_type.all_role.size == 2 &&
            @fact_type.all_role.
              detect do |r|
                r.all_role_ref.detect do |rr|
                  rr.role_sequence.all_presence_constraint.detect do |pc|
                    pc.max_frequency == 1 && !pc.enforcement
                  end
                end
              end

          # If there's an existing presence constraint that can be converted into a PC, do that:
          @clauses.each do |clause|
            rr = clause.role_refs[-1] or next
            epc = rr.embedded_presence_constraint or next
            epc.max_frequency == 1 or next
            next if epc.enforcement
            epc.is_preferred_identifier = true
            return
          end

          # REVISIT: We need to check uniqueness constraints after processing the whole vocabulary
          # raise "Fact type must be named as it has no identifying uniqueness constraint" unless @name || @fact_type.all_role.size == 1

          @constellation.PresenceConstraint(
            :new,
            :vocabulary => @vocabulary,
            :name => @fact_type.entity_type ? @fact_type.entity_type.name+"PK" : '',
            :role_sequence => @fact_type.preferred_reading.role_sequence,
            :max_frequency => 1,
            :is_preferred_identifier => prefer
          )
        end

        def has_more_adjectives(less, more)
          return false if less.leading_adjective && less.leading_adjective != more.leading_adjective
          return false if less.trailing_adjective && less.trailing_adjective != more.trailing_adjective
          return true
        end

        def verify_matching_roles
          role_refs_by_clause_and_key = {}
          clauses_by_role_refs =
            @clauses.inject({}) do |hash, clause|
              keys = clause.role_refs.map do |rr|
                key = rr.key.compact
                role_refs_by_clause_and_key[[clause, key]] = rr
                key
              end.sort_by{|a| a.map{|k|k.to_s}}
              raise "Fact types may not have duplicate roles" if keys.uniq.size < keys.size
              (hash[keys] ||= []) << clause
              hash
            end

          if clauses_by_role_refs.size != 1 and @conditions.empty?
            # Attempt loose binding here; it might merge some Compiler::RoleRefs to share the same Bindings
            variants = clauses_by_role_refs.keys
            (clauses_by_role_refs.size-1).downto(1) do |m|   # Start with the last one
              0.upto(m-1) do |l|                              # Try to rebind onto any lower one
                common = variants[m]&variants[l]
                clauses_l = clauses_by_role_refs[variants[l]]
                clauses_m = clauses_by_role_refs[variants[m]]
                l_keys = variants[l]-common
                m_keys = variants[m]-common
                debug :binding, "Try to collapse variant #{m} onto #{l}; diffs are #{l_keys.inspect} -> #{m_keys.inspect}"
                rebindings = 0
                l_keys.each_with_index do |l_key, i|
                  # Find possible rebinding candidates; there must be exactly one.
                  candidates = []
                  (0...m_keys.size).each do |j|
                    m_key = m_keys[j]
                    l_role_ref = role_refs_by_clause_and_key[[clauses_l[0], l_key]]
                    m_role_ref = role_refs_by_clause_and_key[[clauses_m[0], m_key]]
                    debug :binding, "Can we match #{l_role_ref.inspect} (#{i}) with #{m_role_ref.inspect} (#{j})?"
                    next if m_role_ref.player != l_role_ref.player
                    if has_more_adjectives(m_role_ref, l_role_ref)
                      debug :binding, "can rebind #{m_role_ref.inspect} to #{l_role_ref.inspect}"
                      candidates << [m_role_ref, l_role_ref]
                    elsif has_more_adjectives(l_role_ref, m_role_ref)
                      debug :binding, "can rebind #{l_role_ref.inspect} to #{m_role_ref.inspect}"
                      candidates << [l_role_ref, m_role_ref]
                    end
                  end

                  # debug :binding, "found #{candidates.size} rebinding candidates for this role"
                  debug :binding, "rebinding is ambiguous so not attempted" if candidates.size > 1
                  if (candidates.size == 1)
                    candidates[0][0].rebind_to(@context, candidates[0][1])
                    rebindings += 1
                  end

                end
                if (rebindings == l_keys.size)
                  # Successfully rebound this fact type
                  debug :binding, "Successfully rebound clauses #{clauses_l.map{|r|r.inspect}*'; '} on to #{clauses_m.map{|r|r.inspect}*'; '}"
                  break
                else
                  # No point continuing, we failed on this one.
                  raise "All readings in a fact type definition must have matching role players, compare (#{
                      clauses_by_role_refs.keys.map do |keys|
                        keys.map{|key| key*'-' }*", "
                      end*") with ("
                    })"
                end

              end
            end
          # else all clauses already matched
          end
        end

        def to_s
          if @conditions.size > 0
            true
          end
          "FactType: #{(s = super and !s.empty?) ? "#{s} " : '' }#{@clauses.inspect}" +
            if @conditions && !@conditions.empty?
              " where "+@conditions.map{|c| ((j=c.conjunction) ? j+' ' : '') + c.to_s}*' '
            else
              ''
            end +
            (@pragmas && @pragmas.size > 0 ? ", pragmas [#{@pragmas.sort*','}]" : '')

          # REVISIT: @returning = returning
        end
      end

      # An Operation invokes a binary fact type with a unary operator,
      # or a ternary fact type with a binary operator, of the forms:
      # Result = <op> Value1
      # Result = Value1 <op> Value2
      # where the value type of Result is determined from the arguments
      #
      # Each Value may be a Literal, a RoleRef, or another Operation,
      # so we need to recurse down the tree to build the join.
      class Operation
        attr_reader :fact_type

        def identify_players_with_role_name context
          @context ||= context
          all_operands.each { |o|
            o.identify_player(context) if o.is_a?(RoleRef) && o.role_name
          }
        end

        def identify_other_players context
          all_operands.each { |o|
            o.identify_player(context) if o.is_a?(RoleRef) && !o.role_name
          }
        end

        def bind_roles context
          @context ||= context
          all_operands.each do |o|
            o.bind context if o.is_a?(RoleRef)
          end
        end

        def is_naked_object_type
          false
        end

        def includes_literals
          operand_asts.detect{|o|
            o.includes_literals
          }
        end

        def is_equality_comparison
          false
        end

        def operator
          raise "REVISIT: Implement operator access in the operator subclass #{self.class.name}"
        end

        def operand_asts
          raise "REVISIT: Implement operand AST enumeration in the operator subclass #{self.class.name}"
        end

        def operands context = nil
          raise "REVISIT: Implement operand enumeration in the operator subclass #{self.class.name}"
        end

        # Return a RoleRef that refers to the result role of the operator fact type
        # It must not be called until the players are all identified and bound.
        def result
          raise "REVISIT: Implement result production in the operator subclasses"
        end

        def role_refs
          operands @context
        end

        def match_existing_fact_type context
          opnds = operands(context)
          clause_ast = Clause.new(
              (opnds.size > 1 ? [opnds[0]] : []) + [operator, opnds[-1]]
            )

          # REVISIT: All operands must be value-types or simply-identified Entity Types.

          # REVISIT: We should auto-create joins from Entity Types to an identifying ValueType
          # REVISIT: We should traverse up the supertype of ValueTypes to find a DataType
          @fact_type = clause_ast.match_existing_fact_type(context, :exact_type => true)
          return @fact_type if @fact_type

          @fact_type = clause_ast.make_fact_type context.vocabulary
          clause_ast.make_reading context.vocabulary, @fact_type
          @fact_type
        end
      end

        class Comparison < Operation
        attr_accessor :operator, :e1, :e2, :qualifiers, :conjunction
        def initialize operator, e1, e2, qualifiers = []
          @operator, @e1, @e2, @qualifiers = operator, e1, e2, qualifiers
        end

        def leaf_operand
          nil
        end

        def operand_asts
          [@e1, @e2]
        end

        def operands(context)
          operand_asts.map{|t| t.result(context)}
        end

        def all_operands
          Array(e1.leaf_operand || e1.all_operands) +
            Array(e2.leaf_operand || e2.all_operands)
        end

        def result o
          @result ||= RoleRef.new('Boolean')
        end

        def is_equality_comparison
          @operator == '='
        end

        def to_s
        "(#{operator} #{e1.to_s} #{e2.to_s}#{@qualifiers.empty? ? '' : ', ['+@qualifiers*', '+']'})"
        end
      end

      class Sum < Operation
        attr_accessor :terms
        def initialize *terms
          @terms = terms
        end

        def operator
          '+'
        end

        def operand_asts
          terms
        end

        def operands(context)
          terms.map{|t| t.result(context)}
        end

        def all_operands
          @terms.map{|t| Array(t.leaf_operand || t.all_operands) }.flatten
        end

        def role_refs
          @terms
        end

        def result(context)
          # REVISIT: A sum has the type of its first operand. Do we want that?
          @result ||= RoleRef.new(@terms[0].result(context).player.name)
        end

        def to_s
          '(+ ' + @terms.map{|term| "#{term.to_s}" } * ' ' + ')'
        end
      end

      class Product < Operation
        attr_accessor :factors
        def initialize *factors
          @factors = factors
        end

        def operator
          '*'
        end

        def operand_asts
          @factors
        end

        def operands(context)
          @factors.map{|t| t.result(context)}
        end

        def all_operands
          @factors.map{|f| Array(f.leaf_operand || f.all_operands) }.flatten
        end

        def role_refs
          @factors
        end

        def result(context)
          # REVISIT: A product has the type of its first operand. Do we want that?
          @result ||= RoleRef.new(@factors[0].result(context).player.name)
        end

        def to_s
          '(* ' + @factors.map{|factor| "#{factor.to_s}" } * ' ' + ')'
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

        def operand_asts
          [@divisor]
        end

        def operands(context)
          [@divisor.result(context)]
        end

        def all_operands
          Array(@divisor.leaf_operand || @divisor.all_operands)
        end

        def result(context)
          @result ||= RoleRef.new(divisor.result(context).player.name)
        end

        def to_s
          "(/ #{factor.to_s})"
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

        def operand_asts
          [@term]
        end

        def operands(context)
          [@term.result(context)]
        end

        def all_operands
          Array(@term.leaf_operand || @term.all_operands)
        end

        def result(context)
          @result ||= RoleRef.new(term.result(context).player.name)
        end

        def to_s
          "(- #{term.to_s})"
        end
      end

      class FunctionCallChain
        attr_accessor :variable, :calls
        def initialize var, *calls
          @variable = var
          @calls = calls
        end

        def operand_asts
          [@variable]
        end

        def operands(context)
          [@variable.result(context)]
        end

        def result
          # REVISIT: We need to know the result type for each function
          # Here, assume Integer (works for count at least!)
          @result ||= RoleRef.new('Integer')
        end

        def all_operands
          Array(@variable.leaf_operand || @variable.all_operands)
        end

        def to_s
          @variable.to_s + @calls.map{|call| '.'+call.to_s} * ''
        end
      end

      class FunctionCall
        attr_accessor :name, :params
        def initialize name, *params
          @name = name
          @params = params
        end

        def to_s
          "#{@name}(#{@params.map{|param| param.to_s}*', '})"
        end
      end

      class Literal
        attr_accessor :literal, :unit
        def initialize literal, unit
          @literal, @unit = literal, unit
        end

        def to_s
          unit ? "(#{@literal.to_s} in #{unit.to_s})" : @literal.to_s
        end

        def leaf_operand
          self
        end

        def kind
          case @literal
          when String; 'String'
          when Float; 'Real'
          when Numeric; 'Integer'
          when TrueClass, FalseClass; 'Boolean'
          end
        end

        def includes_literals
          true
        end

        def result(context)
          return @result if @result
          vt_name = kind
          (v = context.vocabulary).constellation.ValueType(v, vt_name)
          @result = RoleRef.new(
            vt_name, nil, nil, nil, nil, nil, nil, @literal
          )
          @result.identify_player context
          @result.bind context
          @result
        end

      end

    end
  end
end
