module ActiveFacts
  module Metamodel
    class Role
      def role_type
        #print "\t#{fact_type.default_reading}: "

        # TypeInheritance roles are always functional
        if TypeInheritance === fact_type
          return self == fact_type.supertype ? :supertype : :subtype
        end

        # Always functional if unary:
        return :unary if fact_type.all_role.size == 1

        # A presence constraint over the fact type that
        # ensures there's only one counterpart instance
        all_uniqueness_constraints =
          fact_type.all_role.map do |fact_role|
            fact_role.all_role_ref.map do |rr|
              rr.role_sequence.all_presence_constraint.select do |pc|
                pc.max_frequency == 1
              end
            end
          end.flatten.uniq

        from_1 =
          all_uniqueness_constraints.
            detect do |c|
                [self] == c.role_sequence.all_role_ref.map(&:role)
            end

        # It's to-1 if a UC exists over the FT that doesn't cover this role:
        p = other_roles.sort_by{|r| r.object_id}
        to_1 =
          all_uniqueness_constraints.
            detect do |c|
              c.role_sequence.all_role_ref.map(&:role).sort_by{|r| r.object_id} == p
            end

        if from_1
          return to_1 ? :one_one : :one_many
        else
          return to_1 ? :many_one : :many_many
        end
      end

      def other_roles
        fact_type.all_role-[self]
      end
    end

    class Concept
      def independent?
        @independent ||= is_independent || decide_independence
      end

      def functional_roles
        #puts "\nGet functional_roles for #{name}"
        @functional_roles ||=   # Comment out to not cache the calculation
        all_role.select do |role|
          [:many_one, :many_many].include?(role.role_type) ? false : role
        end.map do |role|
          all_role = role.fact_type.all_role
          if all_role.size == 1
            role
          else
            all_role[all_role[0] == role ? 1 : 0]
          end
        end
      end
    end

    class ValueType
      def decide_independence
        dependent_roles
      end

      def always_independent
        false
      end

      def always_dependent
        false
      end

      def dependent_roles(excluding = [])
        dr = (all_role-excluding).select{ |role| role.role_type == :one_many}
        dr.size != 0 ? dr : nil
      end
    end

    class EntityType
      def functional_roles
        (fact_type ? fact_type.all_role : []) + super
      end

      def always_independent
        false
      end

      def always_dependent
        supertypes.size > 0
      end

      def dependent_roles(excluding = [])
        # Functional roles that aren't TypeInheritance or covered by the PI are dependent:
        pi_roles = preferred_identifier.role_sequence.all_role_ref.map(&:role)
        fr = functional_roles
        dr = (fr-pi_roles-excluding).reject{ |role| TypeInheritance === role.fact_type }
        puts "#{name} dependent roles are #{dr.map{|role| role.fact_type.describe(role)}.inspect}" if dr.size > 0
        dr.size != 0 ? dr : nil
      end

      def decide_independence
        # Subtypes are *always* absorbed, until we add subtype hint support:
        return false if always_dependent

        # Object is independent if it cannot be absorbed into another object:
        absorbee_roles = all_role.select{|r| [:one_one, :many_one, :supertype].include?(r.role_type)}
        absorbee_roles += fact_type.all_role if fact_type

        # REVISIT: Absorption may only take place along mandatory roles

        #
        # This entity type can perhaps be absorbed into another, or the other into it.
        # Make a sensible decision.
        #
        pi_roles = preferred_identifier.role_sequence.all_role_ref.map(&:role)
        # REVISIT: This knocks out too many cases:
        absorbee_roles.reject!{|ar| pi_roles.include?(ar.other_roles[0])}

        return true if absorbee_roles.size == 0

        #all_role.each{|r| puts "\t#{name}: '" + r.fact_type.default_reading + "' is #{r.role_type}"}
        # Must be independent if it will absorb instead of being absorbed:
        puts "Decide whether to absorb #{name}"
        # Independent unless it can be absorbed on all paths (detect a path where it *can't*):
        if absorbee_roles.detect do |role|
            absorbee = role.other_roles[0].concept
            mustnt_absorb =
              case
              when ValueType === absorbee
                "ValueType"  # Never absorb an entity type into a value type
              # When we provide the preferred identifier for the absorbee:
              when absorbee.preferred_identifier.role_sequence.all_role_ref.map(&:role) == [role]
                "we identify it"
              #REVISIT: when the absorbee has more dependent roles that we do
              #  false
              #REVISIT: when the existing relational database has a table of this name
              #  true
              else
                false # Won't absorb on this path
              end
            puts "\t... into #{absorbee.name}, #{mustnt_absorb ? "no (#{mustnt_absorb})" : "yes"}"
            mustnt_absorb
          end
          return true
        end

        # Object is independent if it has dependent attributes
        # ...that cannot absorb this object:
        # and there's more than one place to absorb it
        return true if dependent_roles(absorbee_roles.map{|r| r.other_roles[0]}) and
          absorbee_roles.size != 1

        false
      end

    end
  end
end
