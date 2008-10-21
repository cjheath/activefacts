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
      # Return the array of absorption paths (roles of this object) that could absorb this object or a reference to it
      def absorption_paths
        return @absorption_paths if @absorption_paths
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

      # Return the Concept into which this concept would be absorbed through its role given
      def absorbed_into(role)
        (self == role.fact_type.entity_type && role.concept) ||  # It's a role of this objectified FT
          role.fact_type.entity_type ||                 # This is a role in another objectified FT
          (role.fact_type.all_role-[role])[0].concept   # A normal role played by this concept in a binary FT
      end

      # can_absorb is an array of roles of other Concepts that this concept can absorb
      # It may include roles of concepts into which this one may be absorbed, until we decide which way to go.
      def can_absorb
        @can_absorb ||= []
      end

      # Say whether the independence of this object is still under consideration
      # This is used in detecting dependency cycles, such as occurs in the Metamodel
      attr_accessor :tentative
      attr_writer :independent

      def absorption_cost
        # The absorption cost is the total cost of each absorbed role
      end

      def reference_cost
        # The absorption cost is the total cost of each preferred_identifier role
      end
    end

    class ValueType
      # Say whether this object is currently considered independent or not:
      def independent
        return @independent if @independent != nil

        # Always independent if marked so:
        if is_independent
          @tentative = false
          return @independent = true
        end

        # Never independent unless they can absorb another ValueType or are marked is_independent
        if (can_absorb.detect{|role| !role.fact_type.entity_type and role.concept.is_a? ValueType })
          @tentative = true
          @independent = true   # Possibly independent
        else
          @tentative = false
          @independent = false
        end

        @independent
      end
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
        # puts "Reference from #{name} to #{role.concept.name} requires absorbing #{ absorbed_rs.describe }"
        absorbed_rs.all_role_ref.each do |rr|
          new_rr = RoleRef.new(rs, rs.all_role_ref.size+1, :role => rr.role, :leading_adjective => rr.leading_adjective, :trailing_adjective => rr.trailing_adjective)

          # Create a new JoinPath for this RoleRef (and append the old ones if any):
          if (last_jp = new_rr.all_join_path.last and
            last_jp.input_role.fact_type.entity_type)
            # We don't have counterpart roles for objectified fact types
            output_role = last_jp.input_role
          else
            output_role = (new_rr.role.fact_type.all_role-[new_rr.role])[0]
          end
          # REVISIT: For an input_role in a unary fact_type, output_role will be nil (in case this is a problem)
          JoinPath.new(new_rr, 0, :input_role => role, :output_role => output_role)

          rr.all_join_path.each do |jp|
            JoinPath.new(new_rr, new_rr.all_join_path.size, :input_role => jp.input_role, :output_role => jp.output_role)
          end
        end
      end

      def absorption_paths
        return @absorption_paths if @absorption_paths
        super
        if (fact_type)
          @absorption_paths += fact_type.all_role.map do |fact_role|
            # Perhaps this objectified fact type can be absorbed through one of its roles
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

      # After computing what this EntityType can absorb, return the absorbed roles that aren't in the preferred_identifier:
      def functional_dependencies
        can_absorb - preferred_identifier.role_sequence.all_role_ref.map(&:role)
      end

      # Say whether this object is currently considered independent or not:
      def independent
        return @independent if @independent != nil  # We already make a guess or decision

        @tentative = false

        # Always independent if marked so or nowhere else to go:
        return @independent = true if is_independent || absorption_paths.empty?

        # Subtypes are not independent unless partitioned
        # REVISIT: Support partitioned subtypes here
        return @independent = false if (!supertypes.empty?)

        # If the preferred_identifier includes an auto_assigned ValueType
        # and this object is absorbed in more than one place, we need a table
        # to manage the auto-assignment.
        if absorption_paths.size > 1 &&
          preferred_identifier.role_sequence.all_role_ref.detect {|rr|
            next false unless rr.role.concept.is_a? ValueType
            # REVISIT: Find a better way to determine AutoCounters (ValueType unary role?)
            rr.role.concept.supertype.name =~ /^Auto/
          }
          return @independent = true
        end

        @tentative = true
        @independent = true
      end
    end # EntityType class

    class Vocabulary
      # return an Array of Concepts that will have their own tables
      def tables
        # Strategy:
        # 1) Calculate absorption paths for all Concepts
        #  a. Build the can_absorb list for each Concept (include unaries!)
        #    - Each entry must absorb either a reference or all roles (unless one-to-one; absorption may be either way)
        # 2) Decide which Concepts must be and must not be tables
        #  a. Concepts labelled is_independent are tables
        #  b. Entity types having no absorption paths must be tables
        #  c. subtypes are not tables unless marked is_independent (subtype extension) or partitioned
        #  d. ValueTypes are never tables unless they can absorb other ValueTypes
        #  e. An EntityType having an identifying AutoInc field must be a table unless absorbed along only one path
        #  f. An EntityType having a preferred_identifier containing one absorption path gets absorbed
        #  g. An EntityType that must absorb non-PI roles must be a table unless absorbed exactly once (3NF restriction)
        #  h. supertypes elided if all roles are absorbed into subtypes:
        #    - partitioned subtype exhaustion
        #    - subtype extension where supertype has only PI roles and no AutoInc
        # 3) Handle tentative assignments that can now be resolved
        #  a. Tentatively independent ValueTypes become independent if they absorb dependent ones
        #  b. Surely something else...?
        # 4) Optimise the decision for undecided Concepts
        #  a. evaluate all combinations
        #  b. minimise a cost function
        #   - cost of not absorbing = number of reference roles * number of places absorbed + number of columns in table
        #   - cost of absorbing = number of absorbed columns in absorbed table * number of places absorbed
        # 5) Suggest improvements
        #   Additional cost (or inject ID?) for references to large data types (>32 bytes)
        all_feature.each do |feature|
          next unless feature.is_a? Concept   # REVISIT: Handle Aliases here
          feature.absorption_paths.each do |role|
            into = feature.absorbed_into(role)
            # puts "#{feature.name} can be absorbed into #{into.name}"
            into.can_absorb << role
          end
          # Ensure that all unary roles are in can_absorb also:
          feature.all_role.select{|role| role.fact_type.all_role.size == 1}.each { |role| feature.can_absorb << role }
          feature.independent = nil   # Undecided
          feature.tentative = nil     # Undecided
        end

        # Evaluate the possible independence of each concept, building an array of features of indeterminate status:
        undecided = []
        all_feature.each do |feature|
          next unless feature.is_a? Concept   # REVISIT: Handle Aliases here
          feature.independent
          undecided << feature if (feature.tentative)
        end

        begin
          finalised = []
          undecided.each do |feature|
            if feature.is_a?(ValueType) # This ValueType must be tentatively independent
              if !feature.can_absorb.detect{|role| !role.fact_type.entity_type and role.concept.independent }
                feature.tentative = false
                finalised << feature
              end
            elsif feature.is_a?(EntityType)
              # if the PI contains one role only and it's an absorption path, absorb it.
              # This case is too ugly... there must be a better way to write it.
              pi_roles = feature.preferred_identifier.role_sequence.all_role_ref.map(&:role)
              if pi_roles.size == 1 &&
                  pi_roles[0].concept.is_a?(EntityType) &&
                  feature.absorption_paths.detect{|role| role == pi_roles[0] || !(role.fact_type.entity_type && (role.fact_type.all_role-[role])[0] == pi_roles[0])}
                feature.independent = false
                feature.tentative = false
                finalised << feature
                next
              end

              fd = feature.functional_dependencies

              # if there are no functional deps, always absorb
              # if there are FDs and only one absorption path which is certainly independent, always absorb
              # if there are FDs and more than one absorption path, always independent
              single_fd = fd.size == 1 && (fd[0].fact_type.entity_type || fd[0].concept)

              if (fd.size != 1 ||
                (single_fd &&
                  single_fd.independent &&
                  !single_fd.tentative))
                feature.independent = !(fd.empty? || fd.size == 1)
                feature.tentative = false
                finalised << feature
              end
            end
          end
          undecided -= finalised
        end while !finalised.empty?

        # Now, evaluate all possibilities of the tentative assignments
        # REVISIT: Incomplete. Apparently unnecessary as well... so far.

        all_feature.select { |f| f.independent }
      end
    end

  end
end
