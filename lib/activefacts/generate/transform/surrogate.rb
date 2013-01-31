#
#       ActiveFacts Schema Transform
#       Transform a loaded ActiveFacts vocabulary to suit ActiveRecord
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/vocabulary'
require 'activefacts/persistence'

module ActiveFacts
  module Metamodel
    class ObjectType
      def add_surrogate type_name = 'Auto Counter', suffix = 'ID'
	# Find or assert the surrogate value type
	auto_counter = constellation.ValueType[[[vocabulary.name], type_name]] ||
	  constellation.ValueType(:vocabulary => vocabulary, :name => type_name, :guid => :new)

	# Create a subtype to identify this entity type:
	my_id = constellation.ValueType(:vocabulary => vocabulary, :name => self.name + ' '+suffix, :guid => :new, :supertype => auto_counter)

	# Create a fact type
	identifying_fact_type = constellation.FactType(:guid => :new)
	my_role = constellation.Role(:guid => :new, :fact_type => identifying_fact_type, :ordinal => 0, :object_type => self)
	id_role = constellation.Role(:guid => :new, :fact_type => identifying_fact_type, :ordinal => 1, :object_type => my_id)

	# Create a reading (which needs a RoleSequence)
	reading = constellation.Reading(
	  :fact_type => identifying_fact_type,
	  :ordinal => 0,
	  :role_sequence => [:new],
	  :text => "{0} has {1}"
	)
	constellation.RoleRef(:role_sequence => reading.role_sequence, :ordinal => 0, :role => my_role)
	constellation.RoleRef(:role_sequence => reading.role_sequence, :ordinal => 1, :role => id_role)

	# Create two uniqueness constraints for the one-to-one. Each needs a RoleSequence (two RoleRefs)
	one_id = constellation.PresenceConstraint(
	    :guid => :new,
	    :vocabulary => vocabulary,
	    :name => self.name+'HasOne'+suffix,
	    :role_sequence => [:new],
	    :is_mandatory => true,
	    :min_frequency => 1,
	    :max_frequency => 1,
	    :is_preferred_identifier => false
	  )
	@constellation.RoleRef(:role_sequence => one_id.role_sequence, :ordinal => 0, :role => my_role)

	one_me = constellation.PresenceConstraint(
	    :guid => :new,
	    :vocabulary => vocabulary,
	    :name => self.name+suffix+'IsOfOne'+self.name,
	    :role_sequence => [:new],
	    :is_mandatory => false,
	    :min_frequency => 0,
	    :max_frequency => 1,
	    :is_preferred_identifier => true
	  )
	@constellation.RoleRef(:role_sequence => one_me.role_sequence, :ordinal => 0, :role => id_role)
      end
    end

    class ValueType
      def needs_surrogate
	supertype_names = supertypes_transitive.map(&:name)
	!(supertype_names.include?('Auto Counter') or supertype_names.include?('Guid'))
      end

      def inject_surrogate
	debug :transform_surrogate, "Adding surrogate ID to Value Type"
	add_surrogate('Auto Counter', 'ID')	# REVISIT: This doesn't work because the mapper expects ValueTypes to be self-identifying
      end
    end

    class EntityType
      def identifying_refs_from
	pi = preferred_identifier
	rrs = pi.role_sequence.all_role_ref

#	REVISIT: This is actually a ref to us, not from
#	if absorbed_via
#	  return [absorbed_via]
#	end

	rrs.map do |rr|
	  r = references_from.detect{|ref| rr.role == ref.to_role }
	  raise "fail in identifying_refs_from for #{name}" unless r
	  r
	end
      end

      def needs_surrogate

	# A recursive proc to replace any reference to an Entity Type by its identifying references:
	debug :transform_surrogate_expansion, "Expanding key for #{name}"
	substitute_identifying_refs = proc do |object|
	  if ref = object.absorbed_via
	    # This shouldn't be necessary, but see the absorbed_via comment above.
	    absorbed_into = ref.from
	    debug :transform_surrogate_expansion, "recursing to handle absorption of #{object.name} into #{absorbed_into.name}"
	    [substitute_identifying_refs.call(absorbed_into)]
	  else
	    irf = object.identifying_refs_from
	    debug :transform_surrogate_expansion, "Iterating for #{object.name} over #{irf.inspect}" do
	      irf.each_with_index do |ref, i|
		next if ref.is_unary
		next if ref.to_role.object_type.kind_of?(ActiveFacts::Metamodel::ValueType)
		recurse_to = ref.to_role.object_type

		debug :transform_surrogate_expansion, "#{i}: recursing to expand #{recurse_to.name} key in #{ref}" do
		  irf[i] = substitute_identifying_refs.call(recurse_to)
		end
	      end
	    end
	    irf
	  end
	end
	irf = substitute_identifying_refs.call(self)

	debug :transform_surrogate, "Does #{name} need a surrogate? it's identified by #{irf.inspect}" do

	  pk_fks = identifying_refs_from.map do |ref|
	    ref.to && ref.to.is_table ? ref.to : nil
	  end

	  irf.flatten!

	  # Multi-part identifiers are only allowed if each part is a foreign key (i.e. it's a join table):
	  if irf.size >= 2
	    if pk_fks.include?(nil)
	      debug :transform_surrogate, "#{self.name} needs a surrogate because its multi-part key contains a non-table"
	      return true
	    # REVISIT: elsif pk_fks.detect{ a table with a multi-part key }
	    else
	      debug :transform_surrogate, "#{self.name} is a join table between #{pk_fks.map(&:name).inspect}"
	      return false
	    end
	    return true
	  end

	  # Single-part key. It must be an Auto Counter, or we will add a surrogate

	  identifying_type = irf[0].to
	  if identifying_type.needs_surrogate
	    debug :transform_surrogate, "#{self.name} needs a surrogate because #{irf[0].to.name} is not an AutoCounter"
	    return true
	  end

	  false
	end
      end

      def inject_surrogate
	debug :transform_surrogate, "Injecting a surrogate key into #{self.name}"

	# Disable the preferred identifier:
	pi = preferred_identifier
	debug :transform_surrogate, "pi for #{name} was '#{pi.describe}'"
	pi.is_preferred_identifier = false
	@preferred_identifier = nil   # Kill the cache

	add_surrogate

	debug :transform_surrogate, "pi for #{name} is now '#{preferred_identifier.describe}'"
      end

    end
  end

  module Generate #:nodoc:
    module Transform #:nodoc:
      class Surrogate
	def initialize(vocabulary, *options)
	  @vocabulary = vocabulary
	end

	def generate(out = $stdout)
	  @out = out
	  injections = 
	    @vocabulary.tables.select do |table|
	      table.needs_surrogate
	    end
	  injections.each do |table|
	    table.inject_surrogate
	  end

	  @vocabulary.decide_tables
	end
      end
    end
  end
end

ActiveFacts::Registry.generator('transform/surrogate', ActiveFacts::Generate::Transform::Surrogate)
