#
#       ActiveFacts Generators.
#       Base class for generators of class libraries in any object-oriented language that supports the ActiveFacts API.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
module ActiveFacts
  module Generate
    module OOTraits
      module ObjectType
	# Map the ObjectType name to an OO class name
	def oo_type_name
	  name.words.titlecase
	end

	# Map the OO class name to a default role name
	def oo_default_role_name
          name.words.snakecase
	end
      end

      module Role
	def oo_role_definition
          return if fact_type.entity_type

          if fact_type.all_role.size == 1
	    return "    maybe :#{preferred_role_name}\n"
          elsif fact_type.all_role.size != 2
            # Shouldn't come here, except perhaps for an invalid model
            return  # ternaries and higher are always objectified
          end

          # REVISIT: TypeInheritance
          if fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance)
            # debug "Ignoring role #{self} in #{fact_type}, subtype fact type"
            # REVISIT: What about secondary subtypes?
            # REVISIT: What about dumping the relational mapping when using separate tables?
            return
          end

          return unless is_functional

          counterpart_role = fact_type.all_role.select{|r| r != self}[0]
          counterpart_type = counterpart_role.object_type
          counterpart_role_name = counterpart_role.preferred_role_name
          counterpart_type_default_role_name = counterpart_type.oo_default_role_name

          # It's a one_to_one if there's a uniqueness constraint on the other role:
          one_to_one = counterpart_role.is_functional
          return if one_to_one &&
              false # REVISIT: !@object_types_dumped[counterpart_role.object_type]

          # Find role name:
          role_method = preferred_role_name
          counterpart_role_method = one_to_one ? role_method : "all_"+role_method
          # puts "---"+role.role_name if role.role_name
          if counterpart_role_name != counterpart_type.oo_default_role_name and
	      role_method == self.object_type.oo_default_role_name
#	    debugger
            counterpart_role_method += "_as_#{counterpart_role_name}"
          end

          role_name = role_method
          role_name = nil if role_name == object_type.oo_default_role_name

          as_binary(counterpart_role_name, counterpart_type, is_mandatory, one_to_one, nil, role_name, counterpart_role_method)
	end
      end

      include ActiveFacts::TraitInjector	# Must be last in this module, after all submodules have been defined
    end
  end
end
