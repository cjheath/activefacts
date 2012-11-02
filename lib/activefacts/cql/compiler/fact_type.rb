module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser

      class Query < ObjectType  # A fact type which is objectified (whether derived or not) is also an ObjectType
        attr_reader :context    # Exposed for testing purposes
        attr_reader :conditions

        def initialize name, conditions = nil, returning = nil
          super name
          @conditions = conditions
          @returning = returning || []
        end

        def prepare_roles clauses = nil
          debug :binding, "preparing roles" do
            @context ||= CompilationContext.new(@vocabulary)
            @context.bind clauses||[], @conditions, @returning
          end
        end

        def compile
          # Match roles with players, and match clauses with existing fact types
          prepare_roles unless @context

          @context.left_contraction_allowed = true
          match_condition_fact_types

          # Build the query:
          unless @conditions.empty? and !@returning
            debug :query, "building query for derived fact type" do
              @query = build_variables(@conditions.flatten)
              @roles_by_binding = build_all_steps(@conditions)
              @query.validate
              @query
            end
          end
          @context.left_contraction_allowed = false
          @query
        end

        def match_condition_fact_types
          @conditions.each do |condition|
            next if condition.is_naked_object_type
            # REVISIT: Many conditions will imply a number of different steps, which need to be handled (similar to nested_clauses).
            debug :projection, "matching condition fact_type #{condition.inspect}" do
              fact_type = condition.match_existing_fact_type @context
              raise "Unrecognised fact type #{condition.inspect} in #{self.class}" unless fact_type
            end
          end
        end

        def detect_projection_by_equality condition
          return false unless condition.is_a?(Comparison)
          if is_projected_role(condition.e1)
            condition.project :left
          elsif is_projected_role(condition.e2)
            condition.project :right
          end
        end

        def is_projected_role(rr)
          false
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
          if ec = @clauses.detect{|r| r.is_equality_comparison}
            @clauses.delete(ec)
            @conditions.unshift(ec)
          end
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
            e = @constellation.EntityType[[@vocabulary, @name]]
            raise "You can't objectify #{@name}, it already exists" if e
            e = @constellation.EntityType(@vocabulary, @name, :fact_type => @fact_type, :guid => :new)
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
          # Attach the clause's role references to the projected roles of the query
          clause.refs.each_with_index do |ref, i|
            role, play = @roles_by_binding[ref.binding]
            raise "#{ref} must be a role projected from the conditions" unless role
            raise "#{ref} has already-projected play!" if play.role_ref
            ref.role_ref.play = play
          end
        end

        # A Comparison in the conditions which projects a role is not treated as a comparison, just as projection
        def is_projected_role(rr)
          # rr is a RoleRef on one side of the comparison.
          # If its binding contains a reference from our readings, it's projected.
          rr.binding.refs.detect do |ref|
            @readings.include?(ref.reading)
          end
        end

        def check_compatibility_of_matched_clauses
          # REVISIT: If we have conditions, we must match all given clauses exactly (no side-effects)
          @existing_clauses = @clauses.
            select{ |clause| clause.match_existing_fact_type @context }.
            # subtyping match is not allowed for fact type extension:
            reject{ |clause| clause.side_effects.role_side_effects.detect{|se| se.common_supertype } }.
            sort_by{ |clause| clause.side_effects.cost }
          fact_types = @existing_clauses.map{ |clause| clause.fact_type }.uniq.compact

          return nil if fact_types.empty?   # There are no matched fact types

          if @clauses.size == 1 && @existing_clauses[0].side_effects.cost != 0
            debug :matching, "There's only a single clause, but it's not an exact match"
            return nil
          end

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
            ref = clause.refs[-1] or next
            epc = ref.embedded_presence_constraint or next
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
          refs_by_clause_and_key = {}
          clauses_by_refs =
            @clauses.inject({}) do |hash, clause|
              keys = clause.refs.map do |ref|
                key = ref.key.compact
                refs_by_clause_and_key[[clause, key]] = ref
                key
              end.sort_by{|a| a.map{|k|k.to_s}}
              raise "Fact types may not have duplicate roles" if keys.uniq.size < keys.size
              (hash[keys] ||= []) << clause
              hash
            end

          if clauses_by_refs.size != 1 and @conditions.empty?
            # Attempt loose binding here; it might merge some Compiler::References to share the same Variables
            variants = clauses_by_refs.keys
            (clauses_by_refs.size-1).downto(1) do |m|   # Start with the last one
              0.upto(m-1) do |l|                              # Try to rebind onto any lower one
                common = variants[m]&variants[l]
                clauses_l = clauses_by_refs[variants[l]]
                clauses_m = clauses_by_refs[variants[m]]
                l_keys = variants[l]-common
                m_keys = variants[m]-common
                debug :binding, "Try to collapse variant #{m} onto #{l}; diffs are #{l_keys.inspect} -> #{m_keys.inspect}"
                rebindings = 0
                l_keys.each_with_index do |l_key, i|
                  # Find possible rebinding candidates; there must be exactly one.
                  candidates = []
                  (0...m_keys.size).each do |j|
                    m_key = m_keys[j]
                    l_ref = refs_by_clause_and_key[[clauses_l[0], l_key]]
                    m_ref = refs_by_clause_and_key[[clauses_m[0], m_key]]
                    debug :binding, "Can we match #{l_ref.inspect} (#{i}) with #{m_ref.inspect} (#{j})?"
                    next if m_ref.player != l_ref.player
                    if has_more_adjectives(m_ref, l_ref)
                      debug :binding, "can rebind #{m_ref.inspect} to #{l_ref.inspect}"
                      candidates << [m_ref, l_ref]
                    elsif has_more_adjectives(l_ref, m_ref)
                      debug :binding, "can rebind #{l_ref.inspect} to #{m_ref.inspect}"
                      candidates << [l_ref, m_ref]
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
                      clauses_by_refs.keys.map do |keys|
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
    end
  end
end
