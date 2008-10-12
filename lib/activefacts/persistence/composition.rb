module ActiveFacts
  module Metamodel
    class Role
      def role_type
        # TypeInheritance roles are always 1:1
        if TypeInheritance === fact_type
          return concept == fact_type.supertype ? :supertype : :subtype
        end

        # Always N:1 if unary:
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
                c.role_sequence.all_role_ref.size == 1 and
                c.role_sequence.all_role_ref[0].role == self
            end

        if fact_type.entity_type
          # This is a role in an objectified fact type
          from_1 = true
        else
          # It's to-1 if a UC exists over roles of this FT that doesn't cover this role:
          from_1 = all_uniqueness_constraints.detect{|uc|
            !uc.role_sequence.all_role_ref.detect{|rr| rr.role == self || rr.role.fact_type != fact_type}
          }
        end

        if from_1
          return to_1 ? :one_one : :one_many
        else
          return to_1 ? :many_one : :many_many
        end
      end

      # Each Role of an objectified fact type has no counterpart role; the other player is the objectifying entity.
      # Otherwise return the player of the other role in a binary fact types
      def other_role_player
        fact_type.entity_type ||  # Objectified fact types only have counterpart roles, no self-roles
          (fact_type.all_role-[self])[0].concept  # Only valid for roles in binaries (others must be objectified anyhow)
      end
    end

    class Concept
      # Return the array of absorption paths that could absorb this object
      def absorption_paths
        return @absorption_paths if @absorption_paths
        return @absorption_paths = [] if is_independent
        @absorption_paths =
          all_role.map do |role|
            role_type = role.role_type
            case role_type
            when :supertype,  # Never absorb a supertype into its subtype (REVISIT: until later when we support partitioning)
                 :many_one    # Can't absorb many of these into one of those
              next nil
            when :unary
              # REVISIT: Test this with an objectified unary
              next nil        # Never absorb an object into one if its unaries
            when :subtype,    # This object is a subtype, so can be absorbed. REVISIT: Support subtype separation and partition
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
      # Return all Roles for this object's preferred_identifier
      def reference_roles
        rs = RoleSequence.new(:new)
        preferred_identifier.role_sequence.all_role_ref.each do |rr|
          pr = rr.role.preferred_reference
          RoleRef.new(rs, rs.all_role_ref.size+1, :role => rr.role, :leading_adjective => pr.leading_adjective, :trailing_adjective => pr.trailing_adjective)
        end
        rs
      end

      # Return a RoleSequence with RoleRefs (including JoinPath) for all ValueTypes required to form this EntityType's preferred_identifier
      def absorbed_reference_roles
        rs = RoleSequence.new(:new)
        reference_roles.all_role_ref.each do |rr|
          absorb_reference(rs, rr.role)
        end
        rs
      end

      def absorb_reference(rs, role)
        if role.fact_type.all_role.size == 1
          # raise "Can't compute absorbed_reference_roles for unary role yet"
          RoleRef.new(rs, rs.all_role_ref.size+1, :role => role)
        elsif role.concept.is_a? ValueType
          pr = role.preferred_reference
          RoleRef.new(rs, rs.all_role_ref.size+1, :role => role, :leading_adjective => pr.leading_adjective, :trailing_adjective => pr.trailing_adjective)
        else
          # Add this role as a JoinPath to the referenced object's absorbed_reference_roles
          absorb_entity_reference(rs, role)
        end
      end

      def absorb_entity_reference(rs, role)
        absorbed_rs = role.concept.absorbed_reference_roles
        absorbed_rs.all_role_ref.each do |rr|
          # Clone the existing RoleRef and its JoinPaths:
          new_rr = RoleRef.new(rs, rs.all_role_ref.size+1, :role => rr.role, :leading_adjective => rr.leading_adjective, :trailing_adjective => rr.trailing_adjective)
          rr.all_join_path.each do |jp|
            JoinPath.new(new_rr, new_rr.all_join_path.size+1, :input_role => jp.input_role, :output_role => jp.output_role)
          end
          # Add a new JoinPath
          # output role is the counterpart of the last join_path's input_role or rr.role if no joins
          # Find the input role, called icr
          last_jp = new_rr.all_join_path.last
          icr = last_jp ? last_jp.input_role : new_rr.role
          if icr.fact_type.all_role.size > 2
            raise "Unexpected JoinPath scenario absorbing #{icr.fact_type.describe(icr)} into #{name}"
          end
          other_role = (icr.fact_type.all_role-[icr])[0]
          # For an input_role in a unary fact_type, output_role will be nil
          JoinPath.new(new_rr, new_rr.all_join_path.size+1, :input_role => role, :output_role => other_role)
        end
      end

      def absorption_paths
        return @absorption_paths if @absorption_paths
        super
        if (fact_type)
          @absorption_paths += fact_type.all_role.map do |fact_role|
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
        @absorption_paths
      end
    end
  end
end
