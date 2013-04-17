#
#       ActiveFacts Generators.
#
#       Generate metadata in JSON
#
# Copyright (c) 2013 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/api'
require 'activefacts/persistence'
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

        def generate(out = $>)
	  @metadata = {"types" => {}}

          object_types_dump

	  out.puts ::JSON.pretty_generate(@metadata)
        end

	# Store the metadata for all types into the types section of the @metadata hash
	def object_types_dump
	  types = @metadata["types"]

	  # Compute the relational mapping if not already done:
	  @tables ||= @vocabulary.tables

	  @vocabulary.all_object_type.
	  sort_by{|c| c.name}.each do |o|
	    object_type = o.as_json_metadata

	    types[o.name] = object_type if object_type
	  end
	end

      end
    end
  end

  module Metamodel
    class ObjectType
      def as_json_metadata
	# Using proc avoids polluting the object's namespace with these little methods
	verbalise_role = proc do |role, plural|
	  fc = Array.new(role.fact_type.all_role.size, plural ? 'some' : 'one')
	  fc[role.ordinal] = 'this'
	  role.fact_type.default_reading(fc, false)
	end

	titlize_words = proc do |phrase|
	  phrase && phrase.split(/\s+/).map{|w| w.sub(/^[a-z]/) {|i| i.upcase}}*' '
	end

	role_name = proc do |role|
	  if role.role_name
	    role.role_name
	  else
	    ref = role.preferred_reference
	    [ titlize_words.call(ref.leading_adjective), role.object_type.name, titlize_words.call(ref.trailing_adjective)].compact*' '
	  end
	end

	return nil if name == '_ImplicitBooleanValueType'

	object_type = {}
	object_type["is_main"] = is_table
	object_type["id"] = guid.to_s
	functions = object_type["functions"] = []

	if is_a?(ActiveFacts::Metamodel::EntityType)

	  # Don't emit a binary objectified fact type that plays no roles (except in implicit fact types:
	  if fact_type and fact_type.all_role.size == 2 and all_role.size == 2
	    return nil
	  end

	  # Export the supertypes
	  (supertypes_transitive-[self]).each do |supertype|
	    functions <<
	      {
		"title" => "as #{supertype.name}",
		"type" => "#{supertype.name}"
	      }
	  end

	  # Export the subtypes
	  (subtypes_transitive-[self]).each do |subtype|
	    functions <<
	      {
		"title" => "as #{subtype.name}",
		"type" => "#{subtype.name}"
	      }
	  end

	  # If an objectified fact type, export the fact type's roles
	  if fact_type
	    fact_type.all_role.each do |role|
	      functions <<
		{
		  "title" => "involving #{role_name.call(role)}",
		  "type" => "#{role.object_type.name}",
		  "where" => verbalise_role.call(role, true)  # REVISIT: Need plural setting here!
		}
	    end
	  end
	end

	# Now export the ordinary roles. Get a sorted list first:
	roles = all_role.reject do |role|
	    # supertype and subtype roles get handled separately
	    role.fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance) ||
	      role.fact_type.is_a?(ActiveFacts::Metamodel::LinkFactType)
	  end.sort_by do |role|
	    [role.fact_type.default_reading, role.ordinal]
	  end

	# For binary fact types, collect the count of the times the unadorned counterpart role name occurs, so we can adorn it
	plural_counterpart_counts = roles.inject(Hash.new{0}) do |h, role|
	  next h unless role.fact_type.all_role.size == 2
	  uc = role.all_role_ref.detect do |rr|
	      rs = rr.role_sequence
	      next false if rs.all_role_ref.size != 1   # Looking for a UC over just this one role
	      rs.all_presence_constraint.detect do |pc|
		  next false unless pc.max_frequency == 1   # It's a uniqueness constraint
		  true
		end
	    end
	  next h if uc	# Not a plural role

	  counterpart_role = (role.fact_type.all_role.to_a - [role])[0]
	  h[role_name.call(counterpart_role)] += 1
	  h
	end

	roles.each do |role|
	  type_name = nil
	  counterpart_name = nil

	  if role.fact_type.entity_type and	      # Role is in an objectified fact type
	    # For binary objectified fact types, we traverse directly to the other role, not just to the objectification
	    !(role.fact_type.entity_type.all_role.size == 2 and role.fact_type.all_role.size == 2)

	    type_name = role.fact_type.entity_type.name
	    counterpart_name = type_name	  # If self plays more than one role in OFT, need to construct a role name
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
	    counterpart_name = role_name.call(counterpart_role)
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
	    if plural_counterpart_counts[counterpart_name] > 1
	      counterpart_name += " as " + role_name.call(role)
	    end
	  end

	  node = {
	    "title" => "#{plural ? 'all ' : ''}#{counterpart_name}",
	    "type" => "#{type_name}",
	    "where" => verbalise_role.call(role, plural),
	    "role_id" => role.guid.to_s
	  }
	  node["is_list"] = true if plural
	  functions << node 

	end
	functions.size > 0 ? object_type : nil
      end
    end
  end
end

ActiveFacts::Registry.generator('metadata/json', ActiveFacts::Generate::Metadata::JSON)
