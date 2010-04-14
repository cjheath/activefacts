module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser

      class Constraint < Definition
        def initialize context_note, enforcement
          @context_note = context_note
          @enforcement = enforcement
        end
      end

      class PresenceConstraint < Constraint
        def initialize context_note, enforcement, roles, quantifier, readings
          super context_note, enforcement
        end
      end

      class SetConstraint < Constraint
        def initialize context_note, enforcement, roles, quantifier, readings
          super context_note, enforcement
        end
      end

      class SubsetConstraint < Constraint
        def initialize context_note, enforcement, subset_readings, superset_readings
          super context_note, enforcement
        end
      end

      class EqualityConstraint < Constraint
        def initialize context_note, enforcement, quantifier, readings
          super context_note, enforcement
        end
      end

      class Restriction
        def initialize value_ranges, enforcement
          @value_ranges = value_ranges
          @enforcement = enforcement
        end

        def compile constellation
          vr = constellation.ValueRestriction(:new)
          @value_ranges.each do |range|
            min, max = Array === range ? range : [range, range]
            v_range = constellation.ValueRange(
              min ? [[String === min ? eval(min) : min.to_s, String === min, nil], true] : nil,
              max ? [[String === max ? eval(max) : max.to_s, String === max, nil], true] : nil
            )
            ar = constellation.AllowedRange(vr, v_range)
          end
          apply_enforcement(vr, @enforcement) if @enforcement
          vr
        end
      end

    end
  end
end

