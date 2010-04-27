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

          # REVISIT: Need to apply loose binding over the constrained roles:
          @role_refs.each{ |role| role.identify_player context; role.bind context }

          unmatched_roles = @role_refs.clone
          fact_types =
            @readings.map do |reading|
              fact_type = reading.match_existing_fact_type context
              raise "Unrecognised fact type #{@reading.inspect} in presence constraint" unless fact_type
              fact_type
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

