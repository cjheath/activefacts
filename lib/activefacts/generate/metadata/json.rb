#
#       ActiveFacts Generators.
#
#       Generate metadata in JSON
#
# Copyright (c) 2013 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/api'
require 'json'

module ActiveFacts
  module Generate #:nodoc:
    class Metadata #:nodoc:
      class JSON #:nodoc:
        def initialize(vocabulary, *options)
          @vocabulary = vocabulary
          @vocabulary = @vocabulary.Vocabulary.values[0] if ActiveFacts::API::Constellation === @vocabulary
          options.each{|option| set_option(option) }
        end

        def set_option(option)
        end

        def puts(*a)
          @out.puts *a
        end

        def print(*a)
          @out.print *a
        end

        def generate(out = $>)
          @out = out

	  @metadata = {"types" => {}}

          object_types_dump()

	  @out.puts ::JSON.pretty_generate(@metadata)
        end

	def verbalise_role role, plural
	  fc = Array.new(role.fact_type.all_role.size, plural ? 'some' : 'one')
	  fc[role.ordinal] = 'this'
	  role.fact_type.default_reading(fc, false)
	end

	def object_types_dump
	  types = @metadata["types"]

	  @vocabulary.all_object_type.reject do |o|
	    o.name == '_ImplicitBooleanValueType'
	  end.sort_by{|c| c.name}.each do |o|

	    object_type = {}
	    object_type["is_main"] = false
	    functions = object_type["functions"] = []

	    if o.is_a?(ActiveFacts::Metamodel::EntityType)

	      # Don't emit a binary objectified fact type that plays no roles (except in implicit fact types:
	      if o.fact_type and o.fact_type.all_role.size == 2 and o.all_role.size == 2
		next
	      end

	      # Export the supertypes
	      (o.supertypes_transitive-[o]).each do |supertype|
		functions <<
		  {
		    "as #{supertype.name}" =>
		      {
			"type" => "#{supertype.name}"
		      }
		  }
	      end

	      # Export the subtypes
	      (o.subtypes_transitive-[o]).each do |subtype|
		functions <<
		  {
		    "as #{subtype.name}" =>
		      {
			"type" => "#{subtype.name}"
		      }
		  }
	      end

	      # If an objectified fact tye, export the fact type's roles
	      if o.fact_type
		o.fact_type.all_role.each do |role|
		  functions <<
		    {
		      "involving #{role.role_name || role.object_type.name}" =>
			{
			  "type" => "#{role.object_type.name}",
			  "where" => verbalise_role(role, true)  # REVISIT: Need plural setting here!
			}
		    }
		end
	      end
	    end

	    # Now export the ordinary roles
	    roles = o.all_role.reject do |role|
	      # supertype and subtype roles get handled separately
	      role.fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance) ||
		role.fact_type.is_a?(ActiveFacts::Metamodel::ImplicitFactType)
#	    end.sort_by do |role|
#	      # counterpart object is...?
#	      # REVISIT: Consider role.fact_type.entity_type.name
#	      role.object_type.name
	    end

	    roles.each do |role|
	      type_name = nil
	      counterpart_name = nil

	      if role.fact_type.entity_type and	      # Role is in an objectified fact type
		# For binary objectified fact types, we traverse directly to the other role, not just to the objectification
		!(role.fact_type.entity_type.all_role.size == 2 and role.fact_type.all_role.size == 2)

		type_name = role.fact_type.entity_type.name
		counterpart_name = type_name	  # If "o" plays more than one role in OFT, need to construct a role name
		plural = true
	      elsif role.fact_type.all_role.size == 1
		# Handle unary roles
		type_name = 'boolean'
		counterpart_name = role.fact_type.default_reading
		plural = false
	      else
		# Handle binary roles
		counterpart_role = (role.fact_type.all_role.to_a - [role])[0]
		type_name = counterpart_role.object_type.name
		counterpart_name = counterpart_role.role_name || type_name

		# Figure out whether the counterpart is plural (say "all ..." if so)
		uc = role.all_role_ref.detect do |rr|
		    rs = rr.role_sequence
		    next false if rs.all_role_ref.size != 1   # Looking for a UC over just this one role
		    rs.all_presence_constraint.detect do |pc|
			next false unless pc.max_frequency == 1   # It's a uniqueness constraint
			true
		      end
		  end
		plural = !uc
	      end

	      node = { "type" => "#{type_name}" }
	      functions << { "#{plural ? 'all ' : ''}#{counterpart_name}" => node }
	      node["is_list"] = true if plural

	      node["where"] = verbalise_role(role, plural)
	    end

	    types[o.name] = object_type if functions.size > 0
	  end
	end

      end
    end
  end
end

ActiveFacts::Registry.generator('metadata/json', ActiveFacts::Generate::Metadata::JSON)
