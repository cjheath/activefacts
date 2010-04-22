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
        def initialize context_note, enforcement, roles, quantifier, readings
          super context_note, enforcement
        end

        def compile
          puts "REVISIT: PresenceConstraint#compile is not yet implemented"
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
        def initialize context_note, enforcement, quantifier, readings
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

