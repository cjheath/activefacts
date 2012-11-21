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
    class ValueType
      def needs_surrogate
	false
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
	  r = references_from.detect{|ref| rr.role = ref.to_role }
	  raise "fail in identifying_refs_from for #{name}" unless r
	  r
	end
      end

      def needs_surrogate

	# A recursive proc to replace any reference to an Entity Type by its identifying references:
	debug :transform_ar_expansion, "Expanding key for #{name}"
	substitute_identifying_refs = proc do |object|
	  if object.absorbed_via
	    # This shouldn't be necessary, but see the absorbed_via comment above.
	    absorbed_into = object.absorbed_via.from
	    debug :transform_ar_expansion, "recursing to handle absorption into #{absorbed_into.name}"
	    [substitute_identifying_refs.call(absorbed_into)]
	  else
	    irf = object.identifying_refs_from
	    # debugger if irf.compact.empty?
	    debug :transform_ar_expansion, "Iterating over #{irf.inspect}" do
	      irf.each_with_index do |ref, i|
		next if ref.is_unary
		next if ref.to_role.object_type.kind_of?(ActiveFacts::Metamodel::ValueType)
		recurse_to = ref.to_role.object_type
		debug :transform_ar_expansion, "#{i}: recursing to expand #{recurse_to.name} key in #{ref}" do
		  irf[i] = substitute_identifying_refs.call(recurse_to)
		end
	      end
	    end
	    irf
	  end
	end
	irf = substitute_identifying_refs.call(self)

	# A multi-part key (for a join table)is only ok if the parts have unitary keys.
	# This might become the case after the first pass however...
	# return false if irf.detect{|r| Array(r).size > 1 }

	debug :transform_ar, "#{name} is identified by #{irf.inspect}"

	pk_fks = identifying_refs_from.map do |ref|
	  ref.to.is_table ? ref.to : nil
	end

	irf.flatten!

	# Multi-part identifiers are only allowed if each part is a foreign key (i.e. it's a join table):
	if irf.size >= 2
	  if pk_fks.include?(nil)
	    debug :transform_ar, "#{self.name} needs a surrogate because its multi-part key contains a non-table"
	    return true
	  # REVISIT: elsif pk_fks.detect{ a table with a multi-part key }
	  else
	    debug :transform_ar, "#{self.name} is a join table between #{pk_fks.map(&:name).inspect}"
	  end
	end

	# return true if irf.size >= 2 and this object plays an identifying role for any other

	# Keys that are too big are disqualified:
	# return true if irf.detect do |ref| ref.to_role.data_type.bytes > 32 end

	false
      end

      def inject_surrogate
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
	  @vocabulary.tables.each do |table|
	    unless table.needs_surrogate
	      @out.puts "Need to inject a surrogate key into #{table.name}"
	      table.inject_surrogate
	    end
	  end
	end
      end
    end
  end
end

ActiveFacts::Registry.generator('transform/surrogate', ActiveFacts::Generate::Transform::Surrogate)
