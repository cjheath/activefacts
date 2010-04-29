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
        def initialize context_note, enforcement
          @context_note = context_note
          @enforcement = enforcement
        end

        def apply_enforcement
          @constraint.enforcement = @enforcement
        end
      end

      class PresenceConstraint < Constraint
        def initialize context_note, enforcement, role_refs, quantifier, joins
          super context_note, enforcement
          @role_refs = role_refs
          @quantifier = quantifier
          @joins = joins
        end

        def compile
          #puts "PresenceConstraint.role_refs = #{@role_refs.inspect}"
          #puts "PresenceConstraint.quantifier = #{@quantifier.inspect}"
          #puts "PresenceConstraint.readings = #{@readings.inspect}"

          @readings = @joins.map do |join|
            raise "REVISIT: Join presence constraints not supported yet" if join.size > 1
            join[0]
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
              # Need to apply loose binding over the constrained roles
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

      class SetConstraint < Constraint
        def initialize context_note, enforcement, roles, quantifier, readings
          super context_note, enforcement
        end

        def compile
          puts "REVISIT: SetConstraint#compile is not yet implemented"
        end
      end

      class SubsetConstraint < Constraint
        def initialize context_note, enforcement, subset_readings, superset_readings
          super context_note, enforcement
        end

        def compile
          puts "REVISIT: SubsetConstraint#compile is not yet implemented"
        end
      end

      class EqualityConstraint < Constraint
        def initialize context_note, enforcement, readings
          super context_note, enforcement
        end

        def compile
          puts "REVISIT: EqualityConstraint#compile is not yet implemented"
        end
      end

      class ValueRestriction < Constraint
        def initialize value_ranges, enforcement
          super(nil, enforcement)
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

