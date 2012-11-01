module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser
      class Enforcement
        attr_reader :action, :agent
        def initialize action, agent
          @action = action
          @agent = agent
        end

        def compile constellation, constraint
          constellation.Enforcement(constraint, :enforcement_code => @action, :agent => @agent)
        end
      end

      class ContextNote
        attr_reader :context_kind, :discussion, :who, :agreed_date, :agreed_agents

        def initialize context_kind, discussion, who, agreed
          @context_kind, @discussion, @who, @agreed = context_kind, discussion, who, agreed
          @agreed_date, @agreed_agents = *agreed
        end

        def compile constellation, target
          context_note =
            constellation.ContextNote(
              :new,
              :context_note_kind => @context_kind,
              :discussion => @discussion
            )
          case target
          when ActiveFacts::Metamodel::ObjectType
            context_note.object_type = target
          when ActiveFacts::Metamodel::Constraint
            context_note.constraint = target
          when ActiveFacts::Metamodel::FactType
            context_note.fact_type = target
          end
          if @agreed_date || @agreed_agents
            agreement = constellation.Agreement(context_note)
            agreement.date = @agreed_date if @agreed_date
            @agreed_agents.each do |agent|
              constellation.ContextAgreedBy(agreement, agent)
            end
          end
          if @who && @who.size > 0
            @who.each do |agent|
              constellation.ContextAccordingTo(context_note, agent)
            end
          end
          context_note
        end
      end

      class Constraint < Definition
        def initialize context_note, enforcement, clauses_lists = []
          if context_note.is_a?(Treetop::Runtime::SyntaxNode)
            context_note = context_note.empty? ? nil : context_note.ast
          end
          @context_note = context_note
          @enforcement = enforcement
          @clauses_lists = clauses_lists
        end

        def compile
          @context_note.compile @constellation, @constraint if @context_note
          @constraint
        end

        def loose_binding
          # Override for constraint types that need loose binding (same role player matching with different adjectives)
        end

        def bind_clauses extra = []
          @context = CompilationContext.new(@vocabulary)
          @context.left_contraction_allowed = true

          @context.bind @clauses_lists, extra
          @clauses_lists.map do |clauses_list|
            @context.left_contractable_clause = nil # Don't contract outside this set of clauses
            clauses_list.each do |clause| 
              fact_type = clause.match_existing_fact_type @context
              raise "Unrecognised fact type #{clause.inspect} in #{self.class}" unless fact_type
            end
          end

          # Any constrained roles will be first identified here.
          # This means that they can't introduce role names.
          loose_binding

          # Ok, we have bound all players by subscript/role_name, by adjectives, and by loose binding,
          # and matched all the fact types that matter. Now assemble a join (with all join steps) for
          # each join list, and build an array of the variables that are involved in the join steps.
          @variables_by_list =
            @clauses_lists.map do |clauses_list|
              all_variables_in_clauses(clauses_list)
            end

          warn_ignored_joins
        end

        def warn_ignored_joins
          # Warn about ignored joins
          @clauses_lists.each do |clauses_list|
            fact_types = clauses_list.map{|join| join.var_refs[0].role_ref.role.fact_type}.uniq
            if fact_types.size > 1
              puts "------->>>> Join ignored in #{self.class}: #{fact_types.map{|ft| ft.preferred_reading.expand}*' and '}"
            end
          end
        end

        def loose_bind_wherever_possible
          # Apply loose binding over applicable roles:
          debug :binding, "Loose binding on #{self.class.name}" do
            @clauses_lists.each do |clauses_list|
              clauses_list.each do |clause|
                clause.var_refs.each_with_index do |var_ref, i|
                  next if var_ref.variable.refs.size > 1
#                  if clause.side_effects && !clause.side_effects.role_side_effects[i].residual_adjectives
#                    debug :binding, "Discounting #{var_ref.inspect} as needing loose binding because it has no residual_adjectives"
#                    next
#                  end
                  # This var_ref didn't match any other var_ref. Have a scout around for a suitable partner
                  candidates = @context.variables.
                    select do |key, variable|
                      variable.player == var_ref.variable.player and
                        variable != var_ref.variable and
                        variable.role_name == var_ref.variable.role_name and  # Both will be nil if they match
                        # REVISIT: Don't bind to a variable with a role occurrence in the same clause
                        !variable.refs.detect{|vr|
                          x = vr.clause == clause
                          # puts "Discounting variable #{variable.inspect} as a match for #{var_ref.inspect} because it's already bound to a player in #{var_ref.clause.inspect}" if x
                          x
                        }
                    end.map{|k,b| b}
                  next if candidates.size != 1  # Fail
                  debug :binding, "Loose binding #{var_ref.inspect} to #{candidates[0].inspect}"
                  var_ref.rebind_to(@context, candidates[0].refs[0])
                end
              end
            end
          end
        end

        def loose_bind
          # Apply loose binding over applicable @roles:
          debug :binding, "Check for loose bindings on #{@roles.size} roles in #{self.class.name}" do
            @roles.each do |var_ref|
              if var_ref.variable.refs.size < @clauses_lists.size+1
                debug :binding, "Insufficient bindings for #{var_ref.inspect} (#{var_ref.variable.refs.size}, expected #{@clauses_lists.size+1}), attempting loose binding" do
                  @clauses_lists.each do |clauses_list|
                    candidates = []
                    next if clauses_list.
                      detect do |clause|
                        debug :binding, "Checking #{clause.inspect}"
                        clause.var_refs.
                          detect do |vr|
                            already_bound = vr.variable == var_ref.variable
                            if !already_bound && vr.player == var_ref.player
                              candidates << vr
                            end
                            already_bound
                          end
                      end
                    debug :binding, "Attempting loose binding for #{var_ref.inspect} in #{clauses_list.inspect}, from the following candidates: #{candidates.inspect}"

                    if candidates.size == 1
                      debug :binding, "Rebinding #{candidates[0].inspect} to #{var_ref.inspect}"
                      candidates[0].rebind_to(@context, var_ref)
                    end
                  end
                end
              end
            end
          end
        end

        def common_variables
          @common_variables ||= @variables_by_list[1..-1].inject(@variables_by_list[0]) { |r, b| r & b }
          raise "#{self.class} must cover some of the same roles, see #{@variables_by_list.inspect}" unless @common_variables.size > 0
          @common_variables
        end

        def to_s
          "#{self.class.name.sub(/.*::/,'')}" + (@clauses_lists.size > 0 ? " over #{@clauses_lists.inspect}" : '')
        end
      end

      class PresenceConstraint < Constraint
        def initialize context_note, enforcement, clauses_lists, var_refs, quantifier
          super context_note, enforcement, clauses_lists
          @var_refs = var_refs || []
          @quantifier = quantifier
        end

        def compile
          @clauses = @clauses_lists.map do |clauses_list|
            raise "REVISIT: Join presence constraints not supported yet" if clauses_list.size > 1 or
              clauses_list.detect{|clause| clause.var_refs.detect{|vr| vr.nested_clauses } }
            clauses_list[0]
          end

          bind_clauses @var_refs

          if @var_refs.size > 0
            bind_constrained_roles
          else
            cb = common_variables
            raise "Either/or must have only one duplicated role, not #{cb.inspect}" unless cb.size == 1
            @var_refs = cb[0].refs.reverse # REVISIT: Should have order these by clause, not like this
          end

          role_sequence = @constellation.RoleSequence(:new)
          @var_refs.each do |var_ref|
            raise "The constrained role #{var_ref.inspect} was not found in the invoked fact types" if var_ref.variable.refs.size == 1
            (var_ref.variable.refs-[var_ref]).each do |ref|
              role = (ref.role_ref && ref.role_ref.role) || ref.role
              raise "FactType role not found for #{ref.inspect}" unless role
              @constellation.RoleRef(role_sequence, role_sequence.all_role_ref.size, :role => role)
            end
          end

          @constraint =
            @constellation.PresenceConstraint(
              :new,
              :name => '',
              :vocabulary => @vocabulary,
              :role_sequence => role_sequence,
              :min_frequency => @quantifier.min,
              :max_frequency => @quantifier.max,
              :is_preferred_identifier => false,
              :is_mandatory => @quantifier.min && @quantifier.min > 0
            )
          @enforcement.compile(@constellation, @constraint) if @enforcement
          super
        end

        # In a PresenceConstraint, each role in "each XYZ" must occur in exactly one clauses_list
        def loose_binding
          # loose_bind_wherever_possible
        end

        def bind_constrained_roles
          @var_refs.each do |var_ref|
            if var_ref.variable.refs.size == 1
              # Apply loose binding over the constrained roles
              candidates =
                @clauses.map do |clause|
                  clause.var_refs.select{ |vr| vr.player == var_ref.player }
                end.flatten
              if candidates.size == 1
                debug :binding, "Rebinding #{var_ref.inspect} to #{candidates[0].inspect} in presence constraint"
                var_ref.rebind_to(@context, candidates[0])
              end
            end
          end
        end

        def to_s
          "#{super} #{@quantifier.min}-#{@quantifier.max} over (#{@var_refs.map{|vr| vr.inspect}*', '})"
        end
      end

      class SetConstraint < Constraint
        def initialize context_note, enforcement, clauses_lists
          super context_note, enforcement, clauses_lists
        end

        def warn_ignored_joins
          # No warnings needed here any more
        end

        def role_sequences_for_common_variables ignore_trailing_joins = false
          @clauses_lists.
              zip(@variables_by_list).
              map do |clauses_list, variables|
            # Does this clauses_list involve a join?
            if clauses_list.size > 1 or
              clauses_list.detect{|clause| clause.var_refs.detect{|var_ref| var_ref.nested_clauses } }

              debug :join, "Building join for #{clauses_list.inspect}" do
                debug :join, "Constrained variables are #{@common_variables.inspect}"
                # Every Variable in these clauses becomes a Join Node,
                # and every clause becomes a JoinStep (and a RoleSequence).
                # The returned RoleSequences contains the RoleRefs for the common_variables.

                # Create a join with a join node for every variable and all join steps:
                join = build_join_nodes(clauses_list)
                roles_by_variable = build_all_join_steps(clauses_list)
                join.validate

                # Create the projected RoleSequence for the constraint:
                role_sequence = @constellation.RoleSequence(:new)
                @common_variables.each do |variable|
                  role, join_role = *roles_by_variable[variable]
                  @constellation.RoleRef(role_sequence, role_sequence.all_role_ref.size, :role => role, :join_role => join_role)
                end

                role_sequence
              end
            else
              # There's no join in this clauses_list, just create a role_sequence
              role_sequence = @constellation.RoleSequence(:new)
              join_variables = variables-@common_variables
              unless join_variables.empty? or ignore_trailing_joins && join_variables.size <= 1
                debug :constraint, "REVISIT: #{self.class}: Ignoring join from #{@common_variables.inspect} to #{join_variables.inspect} in #{clauses_list.inspect}"
              end
              @common_variables.each do |variable|
                roles = clauses_list.
                  map do |clause|
                    clause.var_refs.detect{|vr| vr.variable == variable }
                  end.
                  compact.  # A join clause will probably not have the common variable
                  map do |var_ref|
                    var_ref.role_ref && var_ref.role_ref.role or var_ref.role
                  end.
                  compact
                # REVISIT: Should use clause side effects to preserve residual adjectives here.
                @constellation.RoleRef(role_sequence, role_sequence.all_role_ref.size, :role => roles[0])
              end
              role_sequence
            end
          end
        end
      end

      class SubsetConstraint < SetConstraint
        def initialize context_note, enforcement, clauses_lists
          super context_note, enforcement, clauses_lists
          @subset_clauses = @clauses_lists[0]
          @superset_clauses = @clauses_lists[1]
        end

        def compile
          bind_clauses
          common_variables

          role_sequences =
            role_sequences_for_common_variables

          @constraint =
            @constellation.SubsetConstraint(
              :new,
              :vocabulary => @vocabulary,
              :subset_role_sequence => role_sequences[0],
              :superset_role_sequence => role_sequences[1]
            )
          @enforcement.compile(@constellation, @constraint) if @enforcement
          super
        end

        def loose_binding
          loose_bind_wherever_possible
        end
      end

      class SetComparisonConstraint < SetConstraint
        def initialize context_note, enforcement, clauses_lists
          super context_note, enforcement, clauses_lists
        end
      end

      class SetExclusionConstraint < SetComparisonConstraint
        def initialize context_note, enforcement, clauses_lists, roles, quantifier
          super context_note, enforcement, clauses_lists
          @roles = roles || []
          @quantifier = quantifier
        end

        def compile
          bind_clauses @roles
          common_variables

          role_sequences =
            role_sequences_for_common_variables

          @constraint = @constellation.SetExclusionConstraint(
            :new,
            :vocabulary => @vocabulary,
            :is_mandatory => @quantifier.min == 1
          )
          @enforcement.compile(@constellation, @constraint) if @enforcement
          role_sequences.each_with_index do |role_sequence, i|
            @constellation.SetComparisonRoles(@constraint, i, :role_sequence => role_sequence)
          end
          super
        end

        # In a SetExclusionConstraint, each role in "for each XYZ" must occur in each clauses_list
        def loose_binding
          if @roles.size == 0
            loose_bind_wherever_possible
          else
            loose_bind
          end
        end

      end

      class SetEqualityConstraint < SetComparisonConstraint
        def initialize context_note, enforcement, clauses_lists
          super context_note, enforcement, clauses_lists
        end

        def compile
          bind_clauses
          common_variables

          role_sequences =
            role_sequences_for_common_variables

          @constraint = @constellation.SetEqualityConstraint(
            :new,
            :vocabulary => @vocabulary
          )
          @enforcement.compile(@constellation, @constraint) if @enforcement
          role_sequences.each_with_index do |role_sequence, i|
            @constellation.SetComparisonRoles(@constraint, i, :role_sequence => role_sequence)
          end
          super
        end

        def loose_binding
          loose_bind_wherever_possible
        end
      end

      class RingConstraint < Constraint
        Types = %w{acyclic intransitive symmetric asymmetric transitive antisymmetric irreflexive reflexive}
        Pairs = { :intransitive => [:acyclic, :asymmetric, :symmetric], :irreflexive => [:symmetric] }

        def initialize role_sequence, qualifiers
          super nil, nil
          @role_sequence = role_sequence
          @rings, rest = qualifiers.partition{|q| Types.include?(q) }
          qualifiers.replace rest
        end

        def compile
          # Process the ring constraints:
          return if @rings.empty?

          role_refs = @role_sequence.all_role_ref_in_order.to_a
          supertypes_by_position = role_refs.
            map do |role_ref|
              role_ref.role.object_type.supertypes_transitive
            end
          role_pairs = []
          supertypes_by_position.each_with_index do |sts, i|
            (i+1...supertypes_by_position.size).each do |j|
              common_supertype = (sts & supertypes_by_position[j])[0]
              role_pairs << [role_refs[i], role_refs[j], common_supertype] if common_supertype
            end
          end
          if role_pairs.size > 1
            # REVISIT: Verbalise the role_refs better:
            raise "ambiguous #{@rings*' '} ring constraint, consider #{role_pairs.map{|rp| "#{rp[0].inspect}<->#{rp[1].inspect}"}*', '}"
          end
          if role_pairs.size == 0
            raise "No matching role pair found for #{@rings*' '} ring constraint"
          end

          rp = role_pairs[0]

          # Ensure that the keys in Pairs follow others:
          @rings = @rings.partition{|rc| !Pairs.keys.include?(rc.downcase.to_sym) }.flatten

          if @rings.size > 1 and !Pairs[@rings[-1].to_sym].include?(@rings[0].to_sym)
            raise "incompatible ring constraint types (#{@rings*", "})"
          end
          ring_type = @rings.map{|c| c.capitalize}*""

          @constraint = @constellation.RingConstraint(
              :new,
              :vocabulary => @vocabulary,
          #   :name => name,              # Create a name for Ring Constraints?
              :role => rp[0].role,
              :other_role => rp[1].role,
              :ring_type => ring_type
            )

          debug :constraint, "Added #{@constraint.verbalise} #{@constraint.class.roles.keys.map{|k|"#{k} => "+@constraint.send(k).verbalise}*", "}"
          super
        end

        def to_s
          "#{super} #{@rings*','} over #{@clauses_lists.inspect}"
        end
      end

      class ValueConstraint < Constraint
        def initialize value_ranges, units, enforcement
          super nil, enforcement
          @value_ranges = value_ranges
          @units = units
        end

        def compile
          @constraint = @constellation.ValueConstraint(:new)
          raise "Units on value constraints are not yet processed (at line #{'REVISIT'})" if @units
              # @string.line_of(node.interval.first)

          @value_ranges.each do |range|
            min, max = Array === range ? range : [range, range]
            v_range = @constellation.ValueRange(
              min ? [[String === min ? eval(min) : min.to_s, String === min, nil], true] : nil,
              max ? [[String === max ? eval(max) : max.to_s, String === max, nil], true] : nil
            )
            ar = @constellation.AllowedRange(@constraint, v_range)
          end
          @enforcement.compile(@constellation, @constraint) if @enforcement
          super
        end

        def vrto_s vr
          if Array === vr
            min = vr[0]
            max = vr[1]
            if Numeric === min or Numeric === max
              infinite = 1.0/0
              min ||= -infinite
              max ||= infinite
            else
              min ||= 'MIN'
              max ||= 'MAX'
            end
            Range.new(min, max)
          else
            vr
          end
        end

        def to_s
          "#{super} to (#{@value_ranges.map{|vr| vrto_s(vr) }.inspect })#{ @units ? " in #{@units.inspect}" : ''}"
        end
      end

    end
  end
end

