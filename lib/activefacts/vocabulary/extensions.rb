module ActiveFacts
  module Metamodel

    class FactType
      def all_reading_by_ordinal
	all_reading.sort_by{|reading| reading.ordinal}
      end

      def preferred_reading
	all_reading_by_ordinal[0]
      end
    end

    class EntityType
      def preferred_identifier
	if fact_type
	  # For a nested fact type, the PI is a unique constraint over N or N-1 roles
	  fact_roles = fact_type.all_role
	  # debug "Looking for PI on nested fact type #{name}"
	  pi = catch :pi do
	      fact_roles.each{|r|			# Try all roles of the fact type
		  r.all_role_ref.map{|rr|		# All role sequences that reference this role
		      role_sequence = rr.role_sequence

		      # The role sequence is only interesting if it cover only this fact's roles
		      next if role_sequence.all_role_ref.size < fact_roles.size-1
		      next if role_sequence.all_role_ref.size > fact_roles.size
		      next if role_sequence.all_role_ref.detect{|rsr| !(ft = rsr.role.fact_type) || ft != fact_type }

		      # This role sequence is a candidate
		      pc = role_sequence.all_presence_constraint.detect{|c|
			  c.is_preferred_identifier
			}
		      throw :pi, pc if pc
		    }
		}
	      throw :pi, nil
	    end
	  # debug "Got PI #{pi.name} for nested #{name}" if pi
	  # debug "Looking for PI on entity that nests this fact" unless pi
	  raise "Oops, pi for nested fact is #{pi.class}" unless !pi || PresenceConstraint === pi
	  return pi if pi
	end

	# debug "\nLooking for PI for ordinary entity #{name} with #{all_role.size} roles:"
	# debug "Roles are in #{all_role.map{|r| describe_fact_type(r.fact_type, r)}*", "})"
	pi = catch :pi do
	    all_supertypes = supertypes_transitive
	    # debug "PI roles must be played by one of #{all_supertypes.map(&:name)*", "}" if all_supertypes.size > 1
	    all_role.each{|role|
		ftroles = role.fact_type.all_role
		next if ftroles.size > 2	# Skip roles in objectified fact types

		# debug "Considering role in #{describe_fact_type(role.fact_type, role)}"

		# Find the related role which must be included in any PI:
		# Note this works with unary fact types:
		pi_role = ftroles.size == 1 || ftroles[1] == role ? ftroles[0] : ftroles[1]

		next if ftroles.size == 2 && pi_role.concept == self
		# debug "\tConsidering #{pi_role.concept.name} as a PI role"

		# Look in all role sequences that include this related role
		pi_role.all_role_ref.each{|rr|
		    role_sequence = rr.role_sequence  # A role sequence that includes a possible role
		    # debug "\t\tConsidering role sequence #{describe_role_sequence(role_sequence)}"

		    # All roles in this role_sequence to fact types
		    # which (apart from that role) only have roles
		    # played by the original entity type or a supertype.
		    next if role_sequence.all_role_ref.detect{|rsr|
			fact_type_roles = rsr.role.fact_type.all_role
			residual_roles = fact_type_roles-[rsr.role]
			residual_roles.detect{|rfr|
			    !all_supertypes.include?(rfr.concept)
			  }
		      }

		    # Any presence constraint over this role sequence is a candidate
		    rr.role_sequence.all_presence_constraint.detect{|pc|
			# Found it!
			if pc.is_preferred_identifier
			  # debug "found PI #{pc.name}, is_preferred_identifier=#{pc.is_preferred_identifier.inspect}, enforcement=#{pc.enforcement}"
			  throw :pi, pc
			end
		      }
		  }
	      }
	    throw :pi, nil
	  end
	raise "Oops, pi for entity is #{pi.class}" if pi && !(PresenceConstraint === pi)
	# debug "Got PI #{pi.name} for #{name}" if pi

	if !pi && (supertype = identifying_supertype)
	  # debug "PI not found for #{name}, looking in supertype #{supertype.name}"
	  pi = supertype.preferred_identifier
	else
	  # debug "No PI found for #{name}" if !pi
	end
	raise "No PI found for #{name}" unless pi
	pi
      end

      # An array all direct supertypes
      def supertypes
	all_type_inheritance.map{|ti|
	    ti.super_entity_type
	  }
      end

      # An array of self followed by all supertypes in order:
      def supertypes_transitive
	  ([self] + all_type_inheritance.map{|ti|
	      # debug ti.class.roles.verbalise; exit
	      ti.super_entity_type.supertypes_transitive
	    }).flatten.uniq
      end

      # A subtype does not have a identifying_supertype if it defines its own identifier
      def identifying_supertype
	all_type_inheritance.detect{|ti|
	    return ti.super_entity_type if ti.provides_identification
	  }
	return nil
      end
    end

  end
end
