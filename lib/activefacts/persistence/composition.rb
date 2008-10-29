#
# Calculate the relational composition of a given Vocabulary
# The composition consists of decisiona about which Concepts are tables,
# and what columns (absorbed roled) those tables will have.
#
# This module has the following known problems:
#
# * Some one-to-ones absorb in both directions (ET<->FT in Metamodel, Blog model)
#
# * When a subtype has no mandatory roles, we should introduce
#   a binary (is_subtype) to indicate it's that subtype.
#
module ActiveFacts
  module Metamodel
    class Concept
      # Return a RoleSequence containing a RoleRef (with JoinPath) for every column
      # The vocabulary must have first been composed by calling "tables".
      def absorbed_roles
        if @absorbed_roles
          # Recursion guard
          raise "infinite absorption loop on #{name}" if @evaluating
          return @absorbed_roles
        end
        rs = RoleSequence.new(:new)
        @evaluating = true

        # REVISIT: Emit preferred identifier roles first.
        # Care though; an independent subtype absorbs a reference to its superclass, not the preferred_identifier roles
        inject_value_type_role = is_a?(ValueType)

        debug :absorption, "absorbed_roles of #{name} are:" do
          can_absorb.each do |role|
            other_player =
              case
              when role.fact_type.all_role.size == 1; nil
              when !role.fact_type.entity_type || role.fact_type.entity_type == self; role.concept
              else role.fact_type.entity_type
              end

            # When a ValueType is independent, it always absorbs another ValueType.
            # If this is it, it's our chance to also define the value role for this ValueType.
            if (inject_value_type_role && other_player.is_a?(ValueType))
              my_role = (role.fact_type.all_role-[role])[0]
              rr = my_role.preferred_reference.append_to(rs)
              rr.trailing_adjective = "#{rr.trailing_adjective}Value"
              inject_value_type_role = false
            end

            # If the role is unary, or independent, or what we're referring is absorbed elsewhere, emit a reference:
            reference_only = !other_player ||
                other_player.independent ||
                (other_player.is_a?(EntityType) and (via = other_player.absorbed_via) and via != role.fact_type)

            debug :absorption, "#{name} absorbs #{reference_only ? "reference" : "all"} roles#{(other_player && " of "+other_player.name)} because '#{role.fact_type.default_reading}' via #{via && via.describe(role)} #{
                #role.preferred_reference.describe
                role.fact_type.describe(role)
              }" do
              if reference_only
                absorb_reference(rs, role)
                # Objectified Unaries may play additional roles that were't in can_absorb:
                absorb_entity_roles(rs, role.fact_type.entity_type, role) if (!other_player && role.fact_type.entity_type)
              else
                absorb_all_roles(rs, role)
              end
            end
          end
        end
        @evaluating = false
        @absorbed_roles = rs
        @absorbed_roles
      end

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
      def referenced_from(role)
        (self == role.fact_type.entity_type && role.concept) ||  # It's a role of this objectified FT
          role.fact_type.entity_type ||                 # This is a role in another objectified FT
          (role.fact_type.all_role-[role])[0].concept   # A normal role played by this concept in a binary FT
      end

      # Return a RoleSequence with RoleRefs (including JoinPath) for all ValueTypes required to form this EntityType's preferred_identifier
      def absorbed_reference_roles
        rs = RoleSequence.new(:new)
        debug :absorption, "absorbed_reference_roles of #{name} are:" do
          reference_roles.all_role_ref.each do |rr|
            debug :absorption, "absorbed_reference_role of #{name} is #{rr.role.fact_type.describe(rr.role)}"
            absorb_reference(rs, rr.role)
          end
        end
        rs
      end

      # This object is related to a Concept by this role played by that Concept.
      # If it's a ValueType, add the role to this RoleSequence,
      # otherwise add the reference roles for that EntityType.
      # Note that the role may be in an objectified fact type,
      # at either end (self or role.concept).
      def absorb_reference(rs, role)
        if role.concept.is_a? ValueType
          role.preferred_reference.append_to(rs)
        elsif role.fact_type.entity_type != self and role.fact_type.all_role.size == 1
          # A unary fact type, just add it:
          return RoleRef.new(rs, rs.all_role_ref.size+1, :role => role)
        else
          # Add this role as a JoinPath to the referenced object's absorbed_reference_roles
          debug :absorption, "Absorbing reference to #{role.concept.name} into #{name}" do
            absorbed_rs = role.concept.absorbed_reference_roles
            absorbed_rs.all_role_ref.each do |rr|
              new_rr = extend_join_path(rs, role, rr)
            end
          end
        end
      end

      # Absorb (into the RoleSequence) all roles that are absorbed by the player of this role
      def absorb_all_roles(rs, role)
        #debug :absorption, "absorb_all_roles of #{role.fact_type.describe(role)}"

        if role.concept.is_a? ValueType     # Absorb a role played by a ValueType
          role.preferred_reference.append_to(rs)
        elsif role.fact_type.entity_type != self and role.fact_type.all_role.size == 1
          # Absorb a unary role:
          return RoleRef.new(rs, rs.all_role_ref.size+1, :role => role)
        else
          player = role.fact_type.entity_type
          player = role.concept if !player || player == self 
          if player.independent
            absorb_reference(rs, role)
          else
            absorb_entity_roles(rs, player, role)
          end
        end
      end

      def absorb_entity_roles(rs, entity_type, role)
        absorbed_rs = entity_type.absorbed_roles
        absorbed_rs.all_role_ref.each do |rr|
          new_rr = extend_join_path(rs, role, rr)
        end
      end

      # Add a RoleRef to this RoleSequence which traverses this role to the start-point of the existing RoleRef
      def extend_join_path(rs, role, role_ref)
        new_rr = role_ref.append_to(rs)

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

        role_ref.all_join_path.each do |jp|
          JoinPath.new(new_rr, new_rr.all_join_path.size, :input_role => jp.input_role, :output_role => jp.output_role)
        end
        new_rr
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
      # Return a RoleSequence containing the preferred reference to each Role in this object's preferred_identifier
      def reference_roles
        rs = RoleSequence.new(:new)
        preferred_identifier.role_sequence.all_role_ref.each do |rr|
          rr.role.preferred_reference.append_to(rs)
        end
        rs
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

      # Decide whether this object is currently considered independent or not:
      def independent
        return @independent if @independent != nil  # We already make a guess or decision

        @tentative = false

        # Always independent if marked so or nowhere else to go:
        return @independent = true if is_independent || absorption_paths.empty?

        # Subtypes are not independent unless partitioned
        # REVISIT: Support partitioned subtypes here
        if (!supertypes.empty?)
          av = all_type_inheritance_by_subtype.detect{|ti|ti.provides_identification} || all_type_inheritance_by_subtype[0]
          absorbed_via(av)
          return @independent = false
        end

        # If the preferred_identifier includes an auto_assigned ValueType
        # and this object is absorbed in more than one place, we need a table
        # to manage the auto-assignment.
        if absorption_paths.size > 1 &&
          preferred_identifier.role_sequence.all_role_ref.detect {|rr|
            next false unless rr.role.concept.is_a? ValueType
            # REVISIT: Find a better way to determine AutoCounters (ValueType unary role?)
            rr.role.concept.supertype.name =~ /^Auto/
          }
          debug :absorption, "#{name} has an auto-assigned counter in its ID, so must be independent"
          @tentative = false
          return @independent = true
        end

        @tentative = true
        @independent = true
      end

      def absorbed_via(fact_type = nil)
        # puts "#{name} is absorbed via #{fact_type.describe(role)}" if role
        @absorbed_via = fact_type if fact_type
        @absorbed_via
      end
    end # EntityType class

    class RoleRef
      # Append a copy of this reference to this RoleSequence
      def append_to(rs)
        RoleRef.new(rs, rs.all_role_ref.size+1,
          :role => role,
          :leading_adjective => leading_adjective,
          :trailing_adjective => trailing_adjective
        )
      end
    end

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
        # 4) Optimise the decision for undecided Concepts (not yet)
        #  a. evaluate all combinations
        #  b. minimise a cost function
        #   - cost of not absorbing = number of reference roles * number of places absorbed + number of columns in table
        #   - cost of absorbing = number of absorbed columns in absorbed table * number of places absorbed
        # 5) Suggest improvements
        #   Additional cost (or inject ID?) for references to large data types (>32 bytes)
        all_feature.each do |feature|
          next unless feature.is_a? Concept   # REVISIT: Handle Aliases here
          feature.absorption_paths.each do |role|
            into = feature.referenced_from(role)
            # puts "#{feature.name} can be absorbed into #{into.name}"
            into.can_absorb << role
          end
          # Ensure that all unary roles are in can_absorb also (unless objectified, already handled):
          feature.all_role.select{|role|
            role.fact_type.all_role.size == 1 && !role.fact_type.entity_type
          }.each { |role| feature.can_absorb << role }
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
              # If this ValueType could absorb no independent ValueType, it must be independent (absorbs a dependendent one)
              if !feature.can_absorb.detect{|role| !role.fact_type.entity_type and role.concept.independent }
                feature.tentative = false
                finalised << feature
              end
            elsif feature.is_a?(EntityType)

              # Always absorb an objectified unary:
              if feature.fact_type && feature.fact_type.all_role.size == 1
                feature.independent = false
                feature.tentative = false
                finalised << feature
                next
              end

              # If the PI contains one role only, played by an entity type that can absorb us, do that.
              pi_roles = feature.preferred_identifier.role_sequence.all_role_ref.map(&:role)
              if pi_roles.size == 1 &&
                  (into = pi_roles[0].concept).is_a?(EntityType) &&
                  into.absorption_paths.include?(pi_roles[0])
                  # This doesn't work if we already decided that "into" is fully absorbed along one path.
                  # It doesn't seem to be necessary anyhow.
                  #(into.independent || into.tentative)

                feature.can_absorb.delete(pi_roles[0])
                debug :absorption, "#{feature.name} absorbed along its sole reference path into #{into.name}, and reverse absorption prevented"
                feature.absorbed_via(pi_roles[0].fact_type)

                feature.independent = false
                feature.tentative = false
                finalised << feature
                next
              end

              # If there's more than one absorption path and any functional dependencies that can't absorb us, it's independent
              fd = feature.can_absorb.reject{|role| role.role_type == :one_one} - pi_roles
              if (fd.size > 0)
                debug :absorption, "#{feature.name} has functional dependencies so 3NF requires it be independent"
                feature.independent = true
                feature.tentative = false
                finalised << feature
                next
              end

#              # If there's exactly one absorption path into a object that's independent, absorb regardless of FDs
#              This results in !3NF databases
#              if feature.absorption_paths.size == 1 &&
#                  feature.absorption_paths[0].role_type != :one_one
#                absorbee = feature.referenced_from(feature.absorption_paths[0])
#                debug :absorption, "Absorb #{feature.name} along single path, into #{absorbee.name}"
#                feature.independent = false
#                feature.tentative = false
#                finalised << feature
#              end

              # If the feature has only reference roles and any one-to-ones can absorb it, it's fully absorbed (dependent)
              # We don't allow absorption into something we identify.
              one_to_ones, others = (feature.can_absorb-pi_roles).partition{|role| role.role_type == :one_one }
              if others.size == 0 &&
                !one_to_ones.detect{|r|
                  player = r.fact_type.entity_type || r.concept
                  !player.independent ||
                  player.preferred_identifier.role_sequence.all_role_ref.map{|r2|r2.role.concept} == [feature]
                }
                # All one_to_ones are at least tentatively independent, make them independent and we're fully absorbed

                debug :absorption, "#{feature.name} is fully absorbed, into #{one_to_ones.map{|r| r.concept.name}*", "}"
                !one_to_ones.each{|role|
                  into = role.concept
                  into.tentative = false
                  feature.can_absorb.delete role  # Things that absorb us don't want to get this role too
                }
                feature.independent = false
                feature.tentative = false
                finalised << feature
              end

            end
          end
          undecided -= finalised
        end while !finalised.empty?

        # Now, evaluate all possibilities of the tentative assignments
        # REVISIT: Incomplete. Apparently unnecessary as well... so far.
        undecided.each do |feature|
          debug :absorption, "Unable to decide independence of #{feature.name}, going with #{feature.independent && "in"}dependent"
        end

        all_feature.select { |f| f.independent }
      end
    end

  end
end
