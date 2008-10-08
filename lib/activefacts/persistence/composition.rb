module ActiveFacts
  module Metamodel
    class Role
      def role_type
        # TypeInheritance roles are always functional
        if TypeInheritance === fact_type
          return concept == fact_type.supertype ? :supertype : :subtype
        end

        # Always functional if unary:
        return :unary if fact_type.all_role.size == 1

        # List the UCs on this fact type:
        all_uniqueness_constraints =
          fact_type.all_role.map do |fact_role|
            fact_role.all_role_ref.map do |rr|
              rr.role_sequence.all_presence_constraint.select do |pc|
                pc.max_frequency == 1
              end
            end
          end.flatten.uniq

        to_1 =
          all_uniqueness_constraints.
            detect do |c|
                [self] == c.role_sequence.all_role_ref.map(&:role)
            end

        if fact_type.entity_type
          # This is a role in an objectified fact type
          from_1 = true
        else
          # It's to-1 if a UC exists over the FT that doesn't cover this role:
          from_1 = all_uniqueness_constraints.detect{|uc|
            !uc.role_sequence.all_role_ref.detect{|rr| rr.role == self}
          }
        end

        if from_1
          return to_1 ? :one_one : :one_many
        else
          return to_1 ? :many_one : :many_many
        end
      end

      def other_role_player
        fact_type.entity_type ||  # Objectified fact types only have counterpart roles, no self-roles
          (fact_type.all_role-[self])[0].concept  # Only valid for roles in binaries (others must be objectified anyhow)
      end
    end

    class Concept
      # Return the array of absorption paths that could absorb this object
      def absorption_paths
        return @absorption_roles if @absorption_roles
        return @absorption_roles = [] if is_independent
        @absorption_roles =
          all_role.map do |role|
            role_type = role.role_type
            case role_type
            when :supertype,  # Never absorb a supertype into its subtype (until later when we support partitioning)
                 :many_one    # Can't absorb many of these into one of those
              next nil
            when :unary
              # REVISIT: Test this with an objectified unary
              next nil        # Never absorb an object into one if its unaries
            when :subtype,    # This object is a subtype, so can be absorbed
                 :one_many
              next role
            when :one_one     # This object
              # Never absorb an entity type into a value type:
              next nil if ValueType === role.other_role_player and !is_a?(ValueType)
              next role
            else
              raise "Illegal role type, #{role.fact_type.describe(role)} no uniqueness constraint"
            end
          end.compact
      end

      # Say whether the independence of this object is still under consideration
      # This is used in detecting dependency cycles, such as occurs in the Metamodel
      def tentative
        @tentative = true unless defined @tentative
        @tentative
      end

      def tentative=(v)
        @tentative
      end

      # Say whether this object is currently considered independent or not:
      def independent
        return @independent if defined @independent
        raise "REVISIT: Independence of #{name} hasn't been considered yet"
      end

      def independent=(v)
        @independent = v
      end

      def absorption_cost
        # The absorption cost is the total cost of each absorbed role
      end

      def reference_cost
        # The absorption cost is the total cost of each preferred_identifier role
      end
    end

    class ValueType
    end

    class EntityType
      def absorption_paths
        return @absorption_roles if @absorption_roles
        super
        if (fact_type)
          @absorption_roles += fact_type.all_role.map do |fact_role|
            # REVISIT: Perhaps this objectified fact type can be absorbed through one of its roles
            next fact_role if fact_role.all_role_ref.detect{|rr|
              # Look for a UC that covers just this role
              rr.role_sequence.all_role_ref.size == 1 and
                rr.role_sequence.all_presence_constraint.detect { |pc|
                  pc.max_frequency == 1
                }
            }
            next nil
          end.compact
        end
        @absorption_roles
      end
    end
  end
end
