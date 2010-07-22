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
          when ActiveFacts::Metamodel::Concept
            context_note.concept = target
          when ActiveFacts::Metamodel::Constraint
            context_note.constraint = target
          when ActiveFacts::Metamodel::FactType
            context_note.fact_type = target
          end
          if @agreed_date || @agreed_agents
            agreement = constellation.Agreement(context_note, :date => @agreed_date)
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
        def initialize context_note, enforcement, readings_lists = []
          @context_note = context_note
          @enforcement = enforcement
          @readings_lists = readings_lists
        end

        def compile
          @context_note.compile @constellation, @constraint if @context_note
          @constraint
        end

        def loose_binding
          # Override for constraint types that need loose binding (same role player matching with different adjectives)
        end

        # Return the unique array of all bindings in these readings, including in objectification joins
        def all_bindings_in_readings readings
          readings.map do |reading|
            reading.role_refs.map do |rr|
              [rr.binding] + (rr.objectification_join ? all_bindings_in_readings(rr.objectification_join) : [])
            end
          end.
            flatten.
            uniq
        end

        def bind_readings
          @context = CompilationContext.new(@vocabulary)

          @readings_lists.map do |readings_list|
            readings_list.each{ |reading| reading.identify_players_with_role_name(@context) }
            readings_list.each{ |reading| reading.identify_other_players(@context) }
            readings_list.each{ |reading| reading.bind_roles @context }  # Create the Compiler::Bindings
            readings_list.each do |reading| 
              fact_type = reading.match_existing_fact_type @context
              raise "Unrecognised fact type #{reading.inspect} in #{self.class}" unless fact_type
            end
          end

          loose_binding

          # Ok, we have bound all players by subscript/role_name, by adjectives, and by loose binding,
          # and matched all the fact types that matter. Now assemble a join (with all join steps) for
          # each join list, and build an array of the bindings that are involved in the join steps.
          @bindings_by_list =
            @readings_lists.map do |readings_list|
              all_bindings_in_readings(readings_list)
            end

          warn_ignored_joins
        end

        def warn_ignored_joins
          # Warn about ignored joins
          @readings_lists.each do |readings_list|
            fact_types = readings_list.map{|join| join.role_refs[0].role_ref.role.fact_type}.uniq
            if fact_types.size > 1
              puts "------->>>> Join ignored in #{self.class}: #{fact_types.map{|ft| ft.preferred_reading.expand}*' and '}"
            end
          end
        end

        def loose_bind_wherever_possible
          # Apply loose binding over applicable roles:
          debug :binding, "Loose binding on #{self.class.name}" do
            @readings_lists.each do |readings_list|
              readings_list.each do |reading|
                reading.role_refs.each_with_index do |role_ref, i|
                  next if role_ref.binding.refs.size > 1
#                  if reading.side_effects && !reading.side_effects.role_side_effects[i].residual_adjectives
#                    debug :binding, "Discounting #{role_ref.inspect} as needing loose binding because it has no residual_adjectives"
#                    next
#                  end
                  # This role_ref didn't match any other role_ref. Have a scout around for a suitable partner
                  candidates = @context.bindings.
                    select do |key, binding|
                      binding.player == role_ref.binding.player and
                        binding != role_ref.binding and
                        binding.role_name == role_ref.binding.role_name and  # Both will be nil if they match
                        # REVISIT: Don't bind to a binding with a role occurrence in the same reading
                        !binding.refs.detect{|rr|
                          x = rr.reading == reading
                          # puts "Discounting binding #{binding.inspect} as a match for #{role_ref.inspect} because it's already bound to a player in #{role_ref.reading.inspect}" if x
                          x
                        }
                    end.map{|k,b| b}
                  next if candidates.size != 1  # Fail
                  debug :binding, "Loose binding #{role_ref.inspect} to #{candidates[0].inspect}"
                  role_ref.rebind_to(@context, candidates[0].refs[0])
                end
              end
            end
          end
        end

        def loose_bind_roles
          # Apply loose binding over applicable @roles:
          debug :binding, "Check for loose bindings on #{@roles.size} roles in #{self.class.name}" do
            @roles.each do |role_ref|
              role_ref.identify_player @context
              role_ref.bind @context
              if role_ref.binding.refs.size < @readings_lists.size+1
                debug :binding, "Insufficient bindings for #{role_ref.inspect} (#{role_ref.binding.refs.size}, expected #{@readings_lists.size+1}), attempting loose binding" do
                  @readings_lists.each do |readings_list|
                    candidates = []
                    next if readings_list.
                      detect do |reading|
                        debug :binding, "Checking #{reading.inspect}"
                        reading.role_refs.
                          detect do |rr|
                            already_bound = rr.binding == role_ref.binding
                            if !already_bound && rr.player == role_ref.player
                              candidates << rr
                            end
                            already_bound
                          end
                      end
                    debug :binding, "Attempting loose binding for #{role_ref.inspect} in #{readings_list.inspect}, from the following candidates: #{candidates.inspect}"

                    if candidates.size == 1
                      debug :binding, "Rebinding #{candidates[0].inspect} to #{role_ref.inspect}"
                      candidates[0].rebind_to(@context, role_ref)
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
      end

      class PresenceConstraint < Constraint
        def initialize context_note, enforcement, readings_lists, role_refs, quantifier
          super context_note, enforcement, readings_lists
          @role_refs = role_refs || []
          @quantifier = quantifier
        end

        def compile
          @readings = @readings_lists.map do |readings_list|
            raise "REVISIT: Join presence constraints not supported yet" if readings_list.size > 1
            readings_list[0]
          end

          bind_readings

          if @role_refs.size > 0
            bind_roles
          else
            cb = common_bindings
            raise "Either/or must have only one duplicated role, not #{cb.inspect}" unless cb.size == 1
            @role_refs = cb[0].refs.reverse # REVISIT: Should have order these by reading, not like this
          end

          role_sequence = @constellation.RoleSequence(:new)
          @role_refs.each do |role_ref|
            raise "The constrained role #{role_ref.inspect} was not found in the invoked fact types" if role_ref.binding.refs.size == 1
            (role_ref.binding.refs-[role_ref]).each do |ref|
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

        # In a PresenceConstraint, each role in "each XYZ" must occur in exactly one readings_list
        def loose_binding
          # loose_bind_wherever_possible
        end

        def bind_roles
          @role_refs.each do |role_ref|
            role_ref.identify_player @context
            role_ref.bind @context
            if role_ref.binding.refs.size == 1
              # Apply loose binding over the constrained roles
              candidates =
                @readings.map do |reading|
                  reading.role_refs.select{ |rr| rr.player == role_ref.player }
                end.flatten
              if candidates.size == 1
                debug :binding, "Rebinding #{role_ref.inspect} to #{candidates[0].inspect} in presence constraint"
                role_ref.rebind_to(@context, candidates[0])
              end
            end
          end
        end

      end

      class SetConstraint < Constraint
        def initialize context_note, enforcement, readings_lists
          super context_note, enforcement, readings_lists
        end

        def warn_ignored_joins
          # No warnings needed here any more
        end

        # Make a JoinNode for every binding present in these readings
        def build_join_nodes(readings_list)
          debug :join, "Building join nodes" do
            join = @constellation.Join(:new)
            all_bindings_in_readings(readings_list).
              each do |binding|
                debug :join, "Creating join node #{join.all_join_node.size} for #{binding.inspect}"
                binding.join_node = @constellation.JoinNode(join, join.all_join_node.size, :concept => binding.player)
              end
            join
          end
        end

        def build_join_steps reading, constrained_rs, objectification_node = nil
          role_sequence = nil
          role_refs = []
          debug :join, "Creating join Role Sequence for #{reading.inspect} with #{reading.role_refs.size} role refs" do
            reading.role_refs.each do |role_ref|
              # These role_refs are the Compiler::RoleRefs. These have associated Metamodel::RoleRefs,
              # but we need new RoleRefs to attach to the join (and save any residual_adjectives)
              binding = role_ref.binding
              role = role_ref.role || role_ref.role_ref.role

              if (reading.fact_type.entity_type)
                # This reading is of an objectified fact type. The second role ref is to a phantom role.
                # We don't need join steps for roles that have only one role_ref (this one) in their binding
                refs_count = binding.refs.size
                objectification_ref_count = 0
                role_ref.objectification_join.each{|r| objectification_ref_count += r.role_refs.select{|rr| rr.binding.refs.size > 1}.size} if role_ref.objectification_join
                refs_count += objectification_ref_count
                debug :join, "#{refs_count > 1 ? 'Creating' : 'Skipping'} Role Ref #{role_ref.inspect} (counts #{refs_count}/#{objectification_ref_count}) and objectification Join Step for #{role_ref.inspect}" do

                  if (refs_count > 1)
                    role_sequence ||= @constellation.RoleSequence(:new)
                    role_refs <<
                      @constellation.RoleRef(role_sequence, role_sequence.all_role_ref.size, :role => role, :join_node => binding.join_node)
                    unless objectification_node
                      # We need to create a JoinNode for this object, even though it has no RoleRefs
                      # REVISIT: Or just complain and make the user show the objectification explicitly. Except that doesn't work, see Warehouse...
                      raise "Can't join over fact type '#{reading.fact_type.default_reading}' because it's not objectified" unless reading.fact_type.entity_type
                      join = binding.join_node.join
                      debug :join, "Creating join node #{join.all_join_node.size} for #{reading.fact_type.entity_type.name} in objectification"
                      objectification_node = @constellation.JoinNode(join, join.all_join_node.size, :concept => reading.fact_type.entity_type)
                    end
                    @constellation.RoleRef(role_sequence, 1, :role => role.implicit_fact_type.all_role.single, :join_node => objectification_node)
                    js = @constellation.JoinStep(objectification_node, binding.join_node, :fact_type => role.implicit_fact_type)
                    debug :join, "New Join Step #{js.describe}"
                    role_sequence = nil # Make a new role sequence for the next role, if any
                  end
                end
              else
                debug :join, "Creating Role Ref for #{role_ref.inspect}" do
                  role_sequence ||= @constellation.RoleSequence(:new)
                  role_refs <<
                    @constellation.RoleRef(role_sequence, role_sequence.all_role_ref.size, :role => role, :join_node => binding.join_node)
                end
              end

              if role_ref.objectification_join
                # We are looking at a role whose player is an objectification of a fact type,
                # which will have ImplicitFactTypes for each role.
                # Each of these ImplicitFactTypes has a single phantom role played by the objectifying entity type
                # One of these phantom roles is likely to be the subject of an objectification join step.
                role_ref.objectification_join.each do |r|
                  debug :join, "Building objectification join for #{role_ref.objectification_join.inspect}" do
                    build_join_steps r, constrained_rs, binding.join_node
                  end
                end
              end
              if (@common_bindings.include?(binding))
                debug :join, "#{binding.inspect} is a constrained binding, add the Role Ref for #{role.concept.name}"
                @constellation.RoleRef(constrained_rs, constrained_rs.all_role_ref.size, :role => role, :join_node => binding.join_node)
              end
            end
          end

          if role_sequence
            if !reading.fact_type.entity_type and role = reading.fact_type.all_role.single
              # REVISIT: It might prove to be evil to use the same JoinNode twice for the same JoinStep here... but I don't have a real 
              role_refs <<
                @constellation.RoleRef(role_sequence, role_sequence.all_role_ref.size, :role => role.implicit_fact_type.all_role.single, :join_node => role_sequence.all_role_ref.single.join_node)
            end
            # We aren't talking about objectification here, so there must be exactly two roles.
            raise "REVISIT: Internal error constructing join for #{reading.inspect}" if role_sequence.all_role_ref.size != 2 && role_refs.size == 2
            js = @constellation.JoinStep(role_refs[0].join_node, role_refs[1].join_node, :fact_type => reading.fact_type)
            debug :join, "New Join Step #{js.describe}"
          end
        end

        def role_sequences_for_common_bindings ignore_trailing_joins = false
          @readings_lists.
              zip(@bindings_by_list).
              map do |readings_list, bindings|
            # Does this readings_list involve a join?
            if readings_list.size > 1 or
              readings_list.detect{|reading| reading.role_refs.detect{|role_ref| role_ref.objectification_join } }

              debug :join, "Building join for #{readings_list.inspect}" do
                debug :join, "Constrained bindings are #{@common_bindings.inspect}"
                # Every Binding in these readings becomes a Join Node,
                # and every reading becomes a JoinStep (and a RoleSequence).
                # The returned RoleSequences contains the RoleRefs for the common_bindings.

                # Create a join with a join node for every binding:
                join = build_join_nodes(readings_list)

                join.role_sequence = @constellation.RoleSequence(:new)
                debug :join, "Building join steps" do
                  readings_list.each do |reading|
                    build_join_steps(reading, join.role_sequence)
                  end
                end
                join.validate

                join.role_sequence
              end
            else
              # There's no join in this readings_list, just create a role_sequence
              role_sequence = @constellation.RoleSequence(:new)
              join_bindings = bindings-@common_bindings
              unless join_bindings.empty? or ignore_trailing_joins && join_bindings.size <= 1
                debug :constraint, "REVISIT: #{self.class}: Ignoring join from #{@common_bindings.inspect} to #{join_bindings.inspect} in #{readings_list.inspect}"
              end
              @common_bindings.each do |binding|
                roles = readings_list.
                  map do |reading|
                    reading.role_refs.detect{|rr| rr.binding == binding }
                  end.
                  compact.  # A join reading will probably not have the common binding
                  map do |role_ref|
                    role_ref.role_ref && role_ref.role_ref.role or role_ref.role
                  end.
                  compact
                # REVISIT: Should use reading side effects to preserve residual adjectives here.
                @constellation.RoleRef(role_sequence, role_sequence.all_role_ref.size, :role => roles[0])
              end
              role_sequence
            end
          end
        end
      end

      class SubsetConstraint < SetConstraint
        def initialize context_note, enforcement, readings_lists
          super context_note, enforcement, readings_lists
          @subset_readings = @readings_lists[0]
          @superset_readings = @readings_lists[1]
        end

        def compile
          bind_readings
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
        def initialize context_note, enforcement, readings_lists
          super context_note, enforcement, readings_lists
        end
      end

      class SetExclusionConstraint < SetComparisonConstraint
        def initialize context_note, enforcement, readings_lists, roles, quantifier
          super context_note, enforcement, readings_lists
          @roles = roles || []
          @quantifier = quantifier
        end

        def compile
          bind_readings
          common_bindings

          role_sequences =
            role_sequences_for_common_bindings

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

        # In a SetExclusionConstraint, each role in "for each XYZ" must occur in each readings_list
        def loose_binding
          if @roles.size == 0
            loose_bind_wherever_possible
          else
            loose_bind_roles
          end
        end

      end

      class SetEqualityConstraint < SetComparisonConstraint
        def initialize context_note, enforcement, readings_lists
          super context_note, enforcement, readings_lists
        end

        def compile
          bind_readings
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

          role_refs = @role_sequence.all_role_ref.to_a
          supertypes_by_position = role_refs.
            map do |role_ref|
              role_ref.role.concept.supertypes_transitive
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
      end

      class ValueConstraint < Constraint
        def initialize value_ranges, enforcement
          super nil, enforcement
          @value_ranges = value_ranges
        end

        def compile
          @constraint = @constellation.ValueConstraint(:new)
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
      end

    end
  end
end

