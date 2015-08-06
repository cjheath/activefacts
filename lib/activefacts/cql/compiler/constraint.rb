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
          context_note.relevant_concept = target.concept
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
          if context_note.is_a?(Treetop::Runtime::SyntaxNode) && !context_note.empty?
            context_note = context_note.empty? ? nil : context_note.ast
	  else
	    context_note = nil	# Perhaps a context note got attached to one of the clauses. Steal it.
	    clauses_lists.detect do |clauses_list|
	      if c = clauses_list.last.context_note
		context_note = c
		clauses_list.last.context_note = nil
	      end
	    end
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
              raise "Negated fact type #{clause.inspect} in #{self.class} is not yet supported" if clause.certainty == false
            end
          end

          # Any constrained roles will be first identified here.
          # This means that they can't introduce role names.
          loose_binding

          # Ok, we have bound all players by subscript/role_name, by adjectives, and by loose binding,
          # and matched all the fact types that matter. Now assemble a query (with all steps) for
          # each query list, and build an array of the bindings that are involved in the steps.
          @bindings_by_list =
            @clauses_lists.map do |clauses_list|
              all_bindings_in_clauses(clauses_list)
            end

          warn_ignored_queries
        end

        def warn_ignored_queries
          # Warn about ignored queries
          @clauses_lists.each do |clauses_list|
            fact_types = clauses_list.map{|clauses| (rr = clauses.refs[0].role_ref) && rr.role.fact_type}.compact.uniq
            if fact_types.size > 1
              raise "------->>>> join ignored in #{self.class}: #{fact_types.map{|ft| ft.preferred_reading.expand}*' and '}"
            end
          end
        end

        def loose_bind_wherever_possible
          # Apply loose binding over applicable roles:
          trace :binding, "Loose binding on #{self.class.name}" do
            @clauses_lists.each do |clauses_list|
              clauses_list.each do |clause|
                clause.refs.each_with_index do |ref, i|
                  next if ref.binding.refs.size > 1
#                  if clause.side_effects && !clause.side_effects.role_side_effects[i].residual_adjectives
#                    trace :binding, "Discounting #{ref.inspect} as needing loose binding because it has no residual_adjectives"
#                    next
#                  end
                  # This ref didn't match any other ref. Have a scout around for a suitable partner
                  candidates = @context.bindings.
                    select do |key, binding|
                      binding.player == ref.binding.player and
                        binding != ref.binding and
                        binding.role_name == ref.binding.role_name and  # Both will be nil if they match
                        # REVISIT: Don't bind to a binding with a role occurrence in the same clause
                        !binding.refs.detect{|vr|
                          x = vr.clause == clause
                          # puts "Discounting binding #{binding.inspect} as a match for #{ref.inspect} because it's already bound to a player in #{ref.clause.inspect}" if x
                          x
                        }
                    end.map{|k,b| b}
                  next if candidates.size != 1  # Fail
                  trace :binding, "Loose binding #{ref.inspect} to #{candidates[0].inspect}"
                  ref.rebind_to(@context, candidates[0].refs[0])
                end
              end
            end
          end
        end

        def loose_bind
          # Apply loose binding over applicable @roles:
          trace :binding, "Check for loose bindings on #{@roles.size} roles in #{self.class.name}" do
            @roles.each do |ref|
              if ref.binding.refs.size < @clauses_lists.size+1
                trace :binding, "Insufficient bindings for #{ref.inspect} (#{ref.binding.refs.size}, expected #{@clauses_lists.size+1}), attempting loose binding" do
                  @clauses_lists.each do |clauses_list|
                    candidates = []
                    next if clauses_list.
                      detect do |clause|
                        trace :binding, "Checking #{clause.inspect}"
                        clause.refs.
                          detect do |vr|
                            already_bound = vr.binding == ref.binding
                            if !already_bound && vr.player == ref.player
                              candidates << vr
                            end
                            already_bound
                          end
                      end
                    trace :binding, "Attempting loose binding for #{ref.inspect} in #{clauses_list.inspect}, from the following candidates: #{candidates.inspect}"

                    if candidates.size == 1
                      trace :binding, "Rebinding #{candidates[0].inspect} to #{ref.inspect}"
                      candidates[0].rebind_to(@context, ref)
                    end
                  end
                end
              end
            end
          end
        end

        def common_bindings
          @common_bindings ||= @bindings_by_list[1..-1].inject(@bindings_by_list[0]) { |r, b| r & b }
          raise "#{self.class} must cover some of the same roles, see #{@bindings_by_list.inspect}" unless @common_bindings.size > 0
          @common_bindings
        end

        def to_s
          "#{self.class.name.sub(/.*::/,'')}" + (@clauses_lists.size > 0 ? " over #{@clauses_lists.inspect}" : '')
        end
      end

      class PresenceConstraint < Constraint
        def initialize context_note, enforcement, clauses_lists, refs, quantifier
          super context_note, enforcement, clauses_lists
          @refs = refs || []
          @quantifier = quantifier
        end

        def compile
          @clauses = @clauses_lists.map do |clauses_list|
            raise "REVISIT: join presence constraints not supported yet" if clauses_list.size > 1 or
              clauses_list.detect{|clause| clause.refs.detect{|vr| vr.nested_clauses } }
            clauses_list[0]
          end

          bind_clauses @refs

          if @refs.size > 0
            bind_constrained_roles
          else
            cb = common_bindings
            raise "Either/or must have only one duplicated role, not #{cb.inspect}" unless cb.size == 1
            @refs = cb[0].refs.reverse # REVISIT: Should have order these by clause, not like this
          end

          role_sequence = @constellation.RoleSequence(:new)
          @refs.each do |ref|
            raise "The constrained role #{ref.inspect} was not found in the invoked fact types" if ref.binding.refs.size == 1
            (ref.binding.refs-[ref]).each do |ref|
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
	  if @quantifier.pragmas
	    @quantifier.pragmas.each do |p|
	      @constellation.ConceptAnnotation(:concept => @constraint.concept, :mapping_annotation => p)
	    end
	  end
          @enforcement.compile(@constellation, @constraint) if @enforcement
	  trace :constraint, "Made new PC GUID=#{@constraint.concept.guid} min=#{@quantifier.min.inspect} max=#{@quantifier.max.inspect} over #{role_sequence.describe}"
          super
        end

        # In a PresenceConstraint, each role in "each XYZ" must occur in exactly one clauses_list
        def loose_binding
          # loose_bind_wherever_possible
        end

        def bind_constrained_roles
          @refs.each do |ref|
            if ref.binding.refs.size == 1
              # Apply loose binding over the constrained roles
              candidates =
                @clauses.map do |clause|
                  clause.refs.select{ |vr| vr.player == ref.player }
                end.flatten
              if candidates.size == 1
                trace :binding, "Rebinding #{ref.inspect} to #{candidates[0].inspect} in presence constraint"
                ref.rebind_to(@context, candidates[0])
              end
            end
          end
        end

        def to_s
          "#{super} #{@quantifier.min}-#{@quantifier.max} over (#{@refs.map{|vr| vr.inspect}*', '})"
        end
      end

      class SetConstraint < Constraint
        def initialize context_note, enforcement, clauses_lists
          super context_note, enforcement, clauses_lists
        end

        def warn_ignored_queries
          # No warnings needed here any more
        end

        def role_sequences_for_common_bindings ignore_trailing_steps = false
          @clauses_lists.
              zip(@bindings_by_list).
              map do |clauses_list, bindings|
            # Does this clauses_list involve a query?
            if clauses_list.size > 1 or
              clauses_list.detect do |clause|
		clause.refs.detect{|ref| ref.nested_clauses } or
		clause.includes_literals
	      end

              trace :query, "Building query for #{clauses_list.inspect}" do
                trace :query, "Constrained bindings are #{@common_bindings.inspect}"
                # Every Binding in these clauses becomes a Variable,
                # and every clause becomes a Step (and a RoleSequence).
                # The returned RoleSequences contains the RoleRefs for the common_bindings.

                # Create a query with a variable for every binding and all steps:
                query = build_variables(clauses_list)
                roles_by_binding = build_all_steps(clauses_list)
                query.validate

                # Create the projected RoleSequence for the constraint:
                role_sequence = @constellation.RoleSequence(:new)
                @common_bindings.each do |binding|
                  role, play = *roles_by_binding[binding]
                  @constellation.RoleRef(role_sequence, role_sequence.all_role_ref.size, :role => role, :play => play)
                end

                role_sequence
              end
            else
              # There's no query in this clauses_list, just create a role_sequence
              role_sequence = @constellation.RoleSequence(:new)
              query_bindings = bindings-@common_bindings
              unless query_bindings.empty? or ignore_trailing_steps && query_bindings.size <= 1
                trace :constraint, "REVISIT: #{self.class}: Ignoring query from #{@common_bindings.inspect} to #{query_bindings.inspect} in #{clauses_list.inspect}"
              end
              @common_bindings.each do |binding|
                roles = clauses_list.
                  map do |clause|
                    clause.refs.detect{|vr| vr.binding == binding }
                  end.
                  compact.  # A query clause will probably not have the common binding
                  map do |ref|
                    ref.role_ref && ref.role_ref.role or ref.role
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
          common_bindings

          role_sequences =
            role_sequences_for_common_bindings

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
          common_bindings

          role_sequences =
            role_sequences_for_common_bindings

          @constraint = @constellation.SetExclusionConstraint(
            :new,
            :vocabulary => @vocabulary,
            :is_mandatory => @quantifier.min == 1
          )
	  if @quantifier.pragmas
	    @quantifier.pragmas.each do |p|
	      @constellation.ConceptAnnotation(:concept => @constraint.concept, :mapping_annotation => p)
	    end
	  end
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
          common_bindings

          role_sequences =
            role_sequences_for_common_bindings

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
        Types = %w{acyclic intransitive stronglyintransitive symmetric asymmetric transitive antisymmetric irreflexive reflexive}
        Pairs = {
          :stronglyintransitive => [:acyclic, :asymmetric, :symmetric],
          :intransitive => [:acyclic, :asymmetric, :symmetric],
          :transitive => [:acyclic],
          :acyclic => [:transitive],
          :irreflexive => [:symmetric]
        }

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
            raise "No matching role pair found for #{@rings*' '} ring constraint over #{role_refs.map(&:role).map(&:object_type).map(&:name).inspect}"
          end

          rp = role_pairs[0]

          # Ensure that the keys in Pairs follow others:
          @rings = @rings.partition{|rc| !Pairs.keys.include?(rc.downcase.to_sym) }.flatten

          if @rings.size > 1 and !(p = Pairs[@rings[-1].to_sym]) and !p.include?(@rings[0].to_sym)
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

          trace :constraint, "Added #{@constraint.verbalise}"
          super
        end

        def to_s
          "#{super} #{@rings*','} over #{@clauses_lists.inspect}"
        end
      end

      class ValueConstraint < Constraint
        def initialize ast, enforcement
          super nil, enforcement
          @value_ranges = ast[:ranges]
          @units = ast[:units]
          @regular_expression = ast[:regular_expression]
        end

	def assert_value(val)
	  if val.is_a?(String)
	    @constellation.Value(eval(val), true, nil)
	  elsif val
	    @constellation.Value(val.to_s, false , nil)
	  else
	    nil
	  end
	end

        def compile
          @constraint = @constellation.ValueConstraint(:new)
          raise "Units on value constraints are not yet processed (at line #{'REVISIT'})" if @units
              # @string.line_of(node.interval.first)

	  if @value_ranges
	    @value_ranges.each do |range|
	      min, max = Array === range ? range : [range, range]
	      v_range = @constellation.ValueRange(
		min && @constellation.Bound(:value => assert_value(min), :is_inclusive => true),
		max && @constellation.Bound(:value => assert_value(max), :is_inclusive => true))
	      ar = @constellation.AllowedRange(@constraint, v_range)
	    end
	  else
	    @constraint.regular_expression = @regular_expression
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
          "#{super} to " +
	  (@value_ranges ?
	    "(#{@value_ranges.map{|vr| vrto_s(vr) }.inspect })#{ @units ? " in #{@units.inspect}" : ''}" :
	    @regular_expression
	  )
        end
      end

    end
  end
end

