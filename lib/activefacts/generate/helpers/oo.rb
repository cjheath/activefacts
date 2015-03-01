#
#       ActiveFacts Generators.
#       Base class for generators of class libraries in any object-oriented language that supports the ActiveFacts API.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/generate/helpers/ordered'
require 'activefacts/generate/traits/oo'

module ActiveFacts
  module Generate

    module Helpers
      # Base class for generators of object-oriented class libraries for an ActiveFacts vocabulary.
      class OO < OrderedDumper  #:nodoc:
        def constraints_dump
          # Stub, not needed.
        end

        def value_type_banner
        end

        def value_type_end
        end

        def entity_type_dump(o)
          o.ordered_dumped!
          pi = o.preferred_identifier

          supers = o.supertypes
          if (supers.size > 0)
            # Ignore identification by a supertype:
            pi = nil if pi && pi.role_sequence.all_role_ref.detect{|rr| rr.role.fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance) }
            subtype_dump(o, supers, pi)
          else
            non_subtype_dump(o, pi)
          end
          pi.ordered_dumped! if pi
        end

        # Dump the roles for an object type (excluding the roles of a fact type which is objectified)
        def roles_dump(o)
          o.all_role.
            select{|role|
              role.fact_type.all_role.size <= 2 &&
                !role.fact_type.is_a?(ActiveFacts::Metamodel::LinkFactType)
            }.
            sort_by{|role|
	      other_role = role.fact_type.all_role.select{|r2| r2 != role}[0] || role
              other_role.preferred_role_name(o) + ':' + role.preferred_role_name(other_role.object_type)
            }.each{|role| 
              role_dump(role)
            }
        end

        def role_dump(role)
          fact_type = role.fact_type
          if fact_type.all_role.size == 1
            unary_dump(role, role.preferred_role_name)
            return
	  end
          return if role.fact_type.entity_type

          if fact_type.all_role.size != 2
            # Shouldn't come here, except perhaps for an invalid model
            return  # ternaries and higher are always objectified
          end

          # REVISIT: TypeInheritance
          if fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance)
            # debug "Ignoring role #{role} in #{fact_type}, subtype fact type"
            # REVISIT: What about secondary subtypes?
            # REVISIT: What about dumping the relational mapping when using separate tables?
            return
          end

          return unless role.is_functional

          other_role = fact_type.all_role.select{|r| r != role}[0]
          other_role_name = other_role.preferred_role_name
          other_player = other_role.object_type

          # It's a one_to_one if there's a uniqueness constraint on the other role:
          one_to_one = other_role.is_functional
          return if one_to_one &&
              !other_role.object_type.ordered_dumped

          # Find role name:
          role_method = role.preferred_role_name
          other_role_method = one_to_one ? role_method : "all_"+role_method
          # puts "---"+role.role_name if role.role_name
          if other_role_name != other_player.oo_default_role_name and
	      role_method == role.object_type.oo_default_role_name
	    # debugger
            other_role_method += "_as_#{other_role_name}"
          end

          role_name = role_method
          role_name = nil if role_name == role.object_type.oo_default_role_name

b = role.ruby_role_definition
puts b

          # binary_dump(role, other_role_name, other_player, role.is_mandatory, one_to_one, nil, role_name, other_role_method)
        end

        def skip_fact_type(f)
          # REVISIT: There might be constraints we have to merge into the nested entity or subtype.  These will come up as un-handled constraints.
          !f.entity_type ||
            f.is_a?(ActiveFacts::Metamodel::TypeInheritance)
        end

        # An objectified fact type has internal roles that are always "has_one":
        def fact_roles_dump(fact_type)
          fact_type.all_role.sort_by{|role|
              role.preferred_role_name(fact_type.entity_type)
            }.each{|role| 
              role_name = role.preferred_role_name(fact_type.entity_type)
              one_to_one = role.is_unique
              as = role_name != role.object_type.oo_default_role_name ? "_as_#{role_name}" : ""
#	      debugger if as != ''
              raise "Fact #{fact_type.describe} type is not objectified" unless fact_type.entity_type
              other_role_method = (one_to_one ? "" : "all_") + 
                fact_type.entity_type.oo_default_role_name +
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
