#
#       ActiveFacts Generators.
#       Base class for generators of class libraries in any object-oriented language that supports the ActiveFacts API.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/generate/helpers/ordered'

module ActiveFacts
  module Generate
    module Helpers
      # Base class for generators of object-oriented class libraries for an ActiveFacts vocabulary.
      class OO < OrderedDumper  #:nodoc:
	def constraints_dump(constraints_used)
	  # Stub, not needed.
	end

	def value_type_banner
	end

	def value_type_end
	end

	# Dump the roles for an object type (excluding the roles of a fact type which is objectified)
	def roles_dump(o)
	  o.all_role.
	    select{|role|
	      role.fact_type.all_role.size <= 2 &&
		!role.fact_type.is_a?(ActiveFacts::Metamodel::ImplicitFactType)
	    }.
	    sort_by{|role|
	      preferred_role_name(role.fact_type.all_role.select{|r2| r2 != role}[0] || role, o)
	    }.each{|role| 
	      role_dump(role)
	    }
	end

	def role_dump(role)
	  return if role.fact_type.entity_type

	  fact_type = role.fact_type
	  if fact_type.all_role.size == 1
	    unary_dump(role, preferred_role_name(role))
	    return
	  elsif fact_type.all_role.size != 2
	    # Shouldn't come here, except perhaps for an invalid model
	    return  # ternaries and higher are always objectified
	  end

	  # REVISIT: TypeInheritance
	  if fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance)
	    # debug "Ignoring role #{role} in #{fact_type}, subtype fact type"
	    return
	  end

	  return unless role.is_functional

	  other_role = fact_type.all_role.select{|r| r != role}[0]
	  other_role_name = preferred_role_name(other_role)
	  other_player = other_role.object_type

	  # It's a one_to_one if there's a uniqueness constraint on the other role:
	  one_to_one = other_role.is_functional
	  return if one_to_one &&
	      !@object_types_dumped[other_role.object_type]

	  # Find role name:
	  role_method = preferred_role_name(role)
	  other_role_method = one_to_one ? role_method : "all_"+role_method
	  # puts "---"+role.role_name if role.role_name
	  if other_role_name != other_player.name.gsub(/ /,'_').snakecase and
	    role_method == role.object_type.name.gsub(/ /,'_').snakecase
	    other_role_method += "_as_#{other_role_name}"
	  end

	  role_name = role_method
	  role_name = nil if role_name == role.object_type.name.gsub(/ /,'_').snakecase

	  binary_dump(role, other_role_name, other_player, role.is_mandatory, one_to_one, nil, role_name, other_role_method)
	end

	def preferred_role_name(role, is_for = nil)
	  return "" if role.fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance)

	  if is_for && role.fact_type.entity_type == is_for && role.fact_type.all_role.size == 1
	    return role.object_type.name.gsub(/[- ]/,'_').snakecase
	  end

	  # debug "Looking for preferred_role_name of #{describe_fact_type(role.fact_type, role)}"
	  reading = role.fact_type.preferred_reading
	  preferred_role_ref = reading.role_sequence.all_role_ref.detect{|reading_rr|
	      reading_rr.role == role
	    }

	  # Unaries are a hack, with only one role for what is effectively a binary:
	  if (role.fact_type.all_role.size == 1)
	    return (role.role_name && role.role_name.snakecase) ||
	      reading.text.gsub(/ *\{0\} */,'').gsub(/[- ]/,'_').downcase
	  end

	  # debug "\tleading_adjective=#{(p=preferred_role_ref).leading_adjective}, role_name=#{role.role_name}, role player=#{role.object_type.name}, trailing_adjective=#{p.trailing_adjective}"
	  role_words = []
	  role_name = role.role_name
	  role_name = nil if role_name == ""

	  # REVISIT: Consider whether NOT to use the adjective if it's a prefix of the role_name
	  la = preferred_role_ref.leading_adjective
	  role_words << la.gsub(/[- ]/,'_') if la && la != "" and !role.role_name

	  role_words << (role_name || role.object_type.name.gsub(/[- ]/,'_'))
	  # REVISIT: Same when trailing_adjective is a suffix of the role_name
	  ta = preferred_role_ref.trailing_adjective
	  role_words << ta.gsub(/[- ]/,'_') if ta && ta != "" and !role_name
	  n = role_words.map{|w| w.gsub(/([a-z])([A-Z]+)/,'\1_\2').downcase}*"_"
	  # debug "\tresult=#{n}"
	  n.gsub(' ','_') 
	end

	def skip_fact_type(f)
	  # REVISIT: There might be constraints we have to merge into the nested entity or subtype.  These will come up as un-handled constraints.
	  !f.entity_type ||
	    f.is_a?(ActiveFacts::Metamodel::TypeInheritance)
	end

	# An objectified fact type has internal roles that are always "has_one":
	def fact_roles_dump(fact_type)
	  fact_type.all_role.sort_by{|role|
	      preferred_role_name(role, fact_type.entity_type)
	    }.each{|role| 
	      role_name = preferred_role_name(role, fact_type.entity_type)
	      one_to_one = role.all_role_ref.detect{|rr|
		rr.role_sequence.all_role_ref.size == 1 &&
		rr.role_sequence.all_presence_constraint.detect{|pc|
		  pc.max_frequency == 1
		}
	      }
	      as = role_name != role.object_type.name.gsub(/ /,'_').snakecase ? "_as_#{role_name}" : ""
	      raise "Fact #{fact_type.describe} type is not objectified" unless fact_type.entity_type
	      other_role_method = (one_to_one ? "" : "all_") + 
		fact_type.entity_type.name.gsub(/ /,'_').snakecase +
		as
	      binary_dump(role, role_name, role.object_type, true, one_to_one, nil, nil, other_role_method)
	    }
	end

	def entity_type_banner
	end

	def entity_type_group_end
	end

	def append_ring_to_reading(reading, ring)
	  # REVISIT: debug "Should override append_ring_to_reading"
	end

	def fact_type_banner
	end

	def fact_type_end
	end

	def constraint_banner
	  # debug "Should override constraint_banner"
	end

	def constraint_end
	  # debug "Should override constraint_end"
	end

	def constraint_dump(c)
	  # debug "Should override constraint_dump"
	end

      end
    end
  end
end
