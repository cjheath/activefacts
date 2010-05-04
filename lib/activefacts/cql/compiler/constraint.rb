module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser
      class Enforcement
        attr_reader :action, :agent
        def initialize action, agent
          @action = action
          @agent = agent
          @constraint = nil
        end
      end

      class Constraint < Definition
        def initialize context_note, enforcement, join_lists = []
          @context_note = context_note
          @enforcement = enforcement
          @join_lists = join_lists
        end

        def apply_enforcement
          @constraint.enforcement = @enforcement
        end

        def bind_joins
          @context = CompilationContext.new(@vocabulary)
          @residual_bindings =
            @join_lists.map do |join_list|
              join_list.each{ |reading| reading.identify_players_with_role_name(@context) }
              join_list.each{ |reading| reading.identify_other_players(@context) }
              join_list.each{ |reading| reading.bind_roles @context }  # Create the Compiler::Bindings
              join_list.each do |reading| 
                fact_type = reading.match_existing_fact_type @context
                raise "Unrecognised fact type #{@reading.inspect} in #{self.class}" unless fact_type
                # REVISIT: Should we complain when any fact type is not binary?
              end

              # Find the bindings that occur more than once in this join_list.
              # They join the readings. Each must occur exactly twice
              all_bindings = []
              bindings_count = {}
              join_list.each do |reading|
                reading.role_refs.each do |rr|
                  all_bindings << rr.binding
                  bindings_count[rr.binding] ||= 0
                  bindings_count[rr.binding] += 1
                end
              end
              join_bindings = bindings_count.
                select{|b,c| c > 1}.
                map do |b, c|
                  raise "Join role #{b.inspect} must occur only twice to form a valid join" if c != 2
                  b
                end
              # At present, only ORM2 implicit joins are allowed.
              # That means the join_bindings may only contain a single element at most
              # (This will be a binding to the constrained object)
              raise "REVISIT: No constraint joins (except ORM2's implicit joins) are currently supported" if join_bindings.size > 1
              residuals = (all_bindings.uniq - join_bindings)
            end

          @common_residuals = @residual_bindings[1..-1].inject(@residual_bindings[0]) { |r, b| r & b }
          raise "#{self.class} must cover some of the same roles, see #{@residual_bindings.inspect}" unless @common_residuals.size > 0

          # Warn about ignored joins
          @join_lists.each do |join_list|
            fact_types = join_list.map{|join| join.role_refs[0].role_ref.role.fact_type}.uniq
            if fact_types.size > 1
              puts "------->>>> Join ignored in #{self.class}: #{fact_types.map{|ft| ft.preferred_reading.expand}*' and '}"
            end
          end

        end

      end

      class PresenceConstraint < Constraint
        def initialize context_note, enforcement, join_lists, role_refs, quantifier
          super context_note, enforcement, join_lists
          @role_refs = role_refs
          @quantifier = quantifier
        end

        def compile
          # REVISIT: Call bind_joins(true) here and constrain the @common_residuals

          @readings = @join_lists.map do |join_list|
            raise "REVISIT: Join presence constraints not supported yet" if join_list.size > 1
            join_list[0]
          end

          context = CompilationContext.new(@vocabulary)
          @readings.each{ |reading| reading.identify_players_with_role_name(context) }
          @readings.each{ |reading| reading.identify_other_players(context) }
          @readings.each{ |reading| reading.bind_roles context }  # Create the Compiler::Bindings

          unmatched_roles = @role_refs.clone
          fact_types =
            @readings.map do |reading|
              fact_type = reading.match_existing_fact_type context
              raise "Unrecognised fact type #{@reading.inspect} in presence constraint" unless fact_type
              fact_type
            end

          @role_refs.each do |role_ref|
            role_ref.identify_player context
            role_ref.bind context
            if role_ref.binding.refs.size == 1
              # Apply loose binding over the constrained roles
              candidates =
                @readings.map do |reading|
                  reading.role_refs.select{ |rr| rr.player == role_ref.player }
                end.flatten
              if candidates.size == 1
                debug :constraint, "Rebinding #{role_ref.inspect} to #{candidates[0].inspect} in presence constraint"
                role_ref.rebind(candidates[0])
              end
            end
          end

          rs = @constellation.RoleSequence(:new)
          @role_refs.each do |role_ref|
            raise "The constrained role #{role_ref.inspect} was not found in the invoked fact types" if role_ref.binding.refs.size == 1
            # REVISIT: Need a better way to extract the referenced role via the fact type:
            role = role_ref.binding.refs.map{|ref| ref && ref.role or ref.role_ref && ref.role_ref.role }.compact[0]
            raise "FactType role not found for #{role_ref.inspect}" unless role
            @constellation.RoleRef(rs, rs.all_role_ref.size, :role => role)
          end

          @constellation.PresenceConstraint(
            :new,
            :name => '',
            :vocabulary => @vocabulary,
            :role_sequence => rs,
            :min_frequency => @quantifier.min,
            :max_frequency => @quantifier.max,
            :is_preferred_identifier => false,
            :is_mandatory => @quantifier.min && @quantifier.min > 0,
            :enforcement => @enforcement && @enforcement.compile
          )
        end
      end

      class SetConstraint < Constraint
        def initialize context_note, enforcement, join_lists
          super context_note, enforcement, join_lists
        end

        def bind_residuals_as_role_sequences ignore_trailing_joins = false
          @join_lists.
            zip(@residual_bindings).
            map do |join_list, residual_bindings|
              rs = @constellation.RoleSequence(:new)
              join_bindings = residual_bindings-@common_residuals
              unless join_bindings.empty? or ignore_trailing_joins && join_bindings.size <= 1
                debug :constraint, "REVISIT: #{self.class}: Ignoring join from #{@common_residuals.inspect} to #{join_bindings.inspect} in #{join_list.inspect}"
              end
              @common_residuals.each do |binding|
                roles = join_list.
                  map do |join|
                    join.role_refs.detect{|rr| rr.binding == binding }
                  end.
                  compact.  # A join reading will probably not have the common binding
                  map do |role_ref|
                    role_ref.role_ref && role_ref.role_ref.role or role_ref.role
                  end.
                  compact
                @constellation.RoleRef(rs, rs.all_role_ref.size, :role => roles[0])
              end
              rs
            end
        end
      end

      class SubsetConstraint < SetConstraint
        def initialize context_note, enforcement, join_lists
          super context_note, enforcement, join_lists
          @subset_join = @join_lists[0]
          @superset_join = @join_lists[1]
        end

        def compile
          bind_joins

          role_sequences =
            bind_residuals_as_role_sequences

          @constellation.SubsetConstraint(
            :new,
            :vocabulary => @vocabulary,
            :subset_role_sequence => role_sequences[0],
            :superset_role_sequence => role_sequences[1],
            :enforcement => @enforcement && @enforcement.compile
          )
        end
      end

      class SetComparisonConstraint < SetConstraint
        def initialize context_note, enforcement, join_lists
          super context_note, enforcement, join_lists
        end
      end

      class SetExclusionConstraint < SetComparisonConstraint
        def initialize context_note, enforcement, join_lists, roles, quantifier
          super context_note, enforcement, join_lists
          @roles = roles
          @quantifier = quantifier
        end

        def compile
          bind_joins
          # REVISIT: Apply loose binding over @roles, if any

          is_either_or = @quantifier.max == nil

          role_sequences =
            bind_residuals_as_role_sequences is_either_or

          if is_either_or
            # We come here when we say "either Aaaa or Bbbb;" - it's a PresenceConstraint not exclusion
            # REVISIT: Change this in the CQLParser.treetop grammar, when we fix PresenceConstraint#compile
            raise "either/or constraint must have one common role" if role_sequences.size != 2 || role_sequences[0].all_role_ref.size != 1
            second_role_ref = role_sequences[1].all_role_ref.single
            @constellation.RoleRef(:role_sequence => role_sequences[0], :ordinal => 1, :role => second_role_ref.role)
            @constellation.deny(second_role_ref)
            @constellation.deny(role_sequences[1])

            constraint = @constellation.PresenceConstraint(
              :new,
              :name => '',
              :vocabulary => @vocabulary,
              :role_sequence => role_sequences[0],
              :min_frequency => @quantifier.min,
              :max_frequency => nil,
              :is_preferred_identifier => false,
              :is_mandatory => true,
              :enforcement => @enforcement && @enforcement.compile
            )
          else
            constraint = @constellation.SetExclusionConstraint(
              :new,
              :vocabulary => @vocabulary,
              :is_mandatory => @quantifier.min == 1,
              :enforcement => @enforcement && @enforcement.compile
            )
            role_sequences.each_with_index do |role_sequence, i|
              @constellation.SetComparisonRoles(constraint, i, :role_sequence => role_sequence)
            end
          end
        end
      end

      class SetEqualityConstraint < SetComparisonConstraint
        def initialize context_note, enforcement, join_lists
          super context_note, enforcement, join_lists
        end

        def compile
          bind_joins

          role_sequences =
            bind_residuals_as_role_sequences

          constraint = @constellation.SetEqualityConstraint(
            :new,
            :vocabulary => @vocabulary,
            :enforcement => @enforcement && @enforcement.compile
          )
          role_sequences.each_with_index do |role_sequence, i|
            @constellation.SetComparisonRoles(constraint, i, :role_sequence => role_sequence)
          end
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

          # Ensure that the keys in RingPairs follow others:
          @rings = @rings.partition{|rc| !RingPairs.keys.include?(rc.downcase.to_sym) }.flatten

          if @rings.size > 1 and !RingPairs[@rings[-1].to_sym].include?(@rings[0].to_sym)
            raise "incompatible ring constraint types (#{@rings*", "})"
          end
          ring_type = @rings.map{|c| c.capitalize}*""

          ring = @constellation.RingConstraint(
              :new,
              :vocabulary => @vocabulary,
          #   :name => name,              # REVISIT: Create a name for Ring Constraints?
              :role => rp[0].role,
              :other_role => rp[1].role,
              :ring_type => ring_type
            )

          debug :constraint, "Added #{ring.verbalise} #{ring.class.roles.keys.map{|k|"#{k} => "+ring.send(k).verbalise}*", "}"
        end
      end

      class ValueRestriction < Constraint
        def initialize value_ranges, enforcement
          super nil, enforcement
          @value_ranges = value_ranges
        end

        def compile constellation
          @constraint = constellation.ValueRestriction(:new)
          @value_ranges.each do |range|
            min, max = Array === range ? range : [range, range]
            v_range = constellation.ValueRange(
              min ? [[String === min ? eval(min) : min.to_s, String === min, nil], true] : nil,
              max ? [[String === max ? eval(max) : max.to_s, String === max, nil], true] : nil
            )
            ar = constellation.AllowedRange(@constraint, v_range)
          end
          apply_enforcement
          @constraint
        end
      end

    end
  end
end

