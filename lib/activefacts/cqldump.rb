#
# Dump to CQL module for ActiveFacts models.
#
# Adds the Model.dump_cql() method.
#
# Copyright (c) 2007 Clifford Heath. Read the LICENSE file.
# Author: Clifford Heath.
#
require 'pp'

module ActiveFacts

  class CQLDumper
    def initialize(model)
      @model = model
    end

    def dump(out = $>)
      @out = out
      @out.puts "// "+ @model.to_s

      build_indices
      dump_value_types()
      dump_entity_types()
      dump_fact_types()
      dump_constraint_types(@constraints_used)
    end

    def build_indices
      @set_constraints_by_fact = @model.constraints.inject({}) { |h, c|
	  if SetConstraint === c
	    fact_types = c.role_sequence.map(&:fact_type).uniq	# All fact types spanned by this constraint
	    if fact_types.size == 1	# There's only one, save it:
	      # $stderr.puts "Single-fact constraint on #{fact_types[0].name}: #{c.name}"
	      (h[fact_types[0]] ||= []) << c
	    end
	  end

	  h
	}
      @constraints_used = {}
      @fact_set_constraints_exhausted = {}
    end

    def dump_value_types
      @model.object_types.sort_by{|o| o.name}.each{|o|
	  next if EntityType === o
	  if o.name == o.data_type.name
	      # In ActiveFacts, parameterising a ValueType will create a new datatype
	      # throw Can't handle parameterized value tpe of saame name as its datatype" if ...
	  end

	  @out.puts "#{o.to_s};"
	}
    end

    def fact_readings_with_constraints(fact_type)
      fact_constraints = @set_constraints_by_fact[fact_type].clone
       readings = fact_type.readings.map{|r|
	    # Find a PresenceConstraint over the last role
	    n = r.name.sub(/.*\{(\d)\}[^\{]*\Z/,'\1')	# Get the Role number from the {n} insertion
	    role = r.role_sequence[n.to_i]		# and the Role object

	    constraint = (n && fact_constraints.find{|c|	# Find a PC that spans all other Roles
		# internal PresenceConstraints span all roles but one, the residual:
		PresenceConstraint === c &&
		  (residual = (fact_type.roles-c.role_sequence)).size == 1 &&
		  residual[0] == role
	      })
	    expand_using = { role => constraint }

	    s = r.to_s(expand_using)
	    if expand_using.size == 0    # Constraint was verbalised
	      fact_constraints -= [constraint]
	      @constraints_used[constraint] = true
	    end
	    s
	}
      if fact_constraints.size == 0
	# We've exhausted the set constraints on this fact type.
	@fact_set_constraints_exhausted[fact_type] = true
      end
      readings
    end

    def dump_entity_type(o)
      pi = o.preferred_identifier

      # REVISIT: Need to include adjectives here:
      identifying_roles = pi.role_sequence.map{|r| r.name }*" and "
      @constraints_used[pi] = true

      # REVISIT: Consider emitting all fact types we can, not just identifying ones?
      # REVISIT: Handle subtypes here

      identifying_facts = pi.role_sequence.map{|r| r.fact_type }.uniq
      #pp identifying_facts.map{|f| f.preferred_reading }
      @out.puts("#{o.name} = entity known by #{ identifying_roles }:\n\t" +
	  identifying_facts.map{|f| fact_readings_with_constraints(f) }.flatten*",\n\t" + ";\n\n")
    end

    def dump_entity_types
      # Try to dump entity types in order of name,
      # but we need to dump ETs before they're referenced in preferred ids.
      # Build hash tables of precursors and followers to use:
      entity_count = 0
      precursors, followers = *@model.object_types.inject([{},{}]) { |a, o|
	  if EntityType === o
	    entity_count += 1
	    precursor = a[0]
	    follower = a[1]
	    blocked = false
	    o.preferred_identifier.role_sequence.each{|r|
		player = r.object_type
		next unless EntityType === player
		# player is a precursor of o
		(precursor[o] ||= []) << player
		(follower[player] ||= []) << o
	      }
	  end
	  a
	}

      sorted = @model.object_types.sort_by{|o| o.name}
      done = {}
      while entity_count > 0 do
	sorted.each{|o|
	    next unless EntityType === o && !done[o]	# Not an ET or already done
	    next if ((p = precursors[o]) && p.size > 0)	# Not yet, still blocked

	    # We're going to emit o - remove it from precursors of others:
	    (followers[o]||[]).each{|f|
		precursors[f] -= [o]
	      }
	    entity_count -= 1
	    done[o] = true

	    dump_entity_type(o)
	  }

      end
    end

    def dump_fact_types
      # REVISIT: Include all simple presence constraints in the fact type readings

      @model.fact_types.each{|f|
	  next if f.nested_as ||  # REVISIT: There might be constraints we have to merge into the nested entity:
	    @fact_set_constraints_exhausted[f]

	  fact_constraints = @set_constraints_by_fact[f]

	  # $stderr.puts "for fact type #{f.to_s}, considering\n\t#{fact_constraints.map(&:to_s)*",\n\t"}"
	  # $stderr.puts "#{f.name} has readings:\n\t#{f.readings.map(&:name)*"\n\t"}"

	  # Omit fact type names from fact types that aren't implicitly nested
	  # We've already skipped explicitly nested fact types.
	  # REVISIT: This should be a method on the fact type
	  name = f.name+" = "
	  name = "" unless fact_constraints.detect{|c|
	      PresenceConstraint === c &&
	      c.role_sequence.size > 1
	    }
	  @out.puts name +
	    fact_readings_with_constraints(f)*",\n\t" +
	    ";"
	  # REVISIT: Go through the residual constraints and re-process appropriate readings to show them
	}
      # unused = constraints - @constraints_used.keys
      # $stderr.puts "residual constraints are\n\t#{unused.map(&:to_s)*",\n\t"}"

      @constraints_used
    end

    def dump_fact_instances
      @model.fact_types.each{|f|
	  # Dump the instances:
	  f.facts.each{|i|
	    @out.puts "\t\t"+i.to_s
	  }
      }
    end

    def dump_constraint_types(except = {})
      heading = false
      @model.constraints.each{|c|
	  next if except[c]

	  # Skip uniqueness constraints that cover all roles of a fact type, they're implicit
	  if ActiveFacts::PresenceConstraint === c &&
	      c.max == 1 &&	    # Uniqueness
	      c.role_sequence.size == c.role_sequence[0].fact_type.roles.size &&	# Same number of roles
	      c.role_sequence[0].fact_type.roles.all?{|r| c.role_sequence.include? r}	# All present
	    next
	  end

	  unless heading
	    @out.puts "\n/*\nConstraints:"
	    heading = true
	  end

	  # Skip presence constraints on value types:
	  # next if ActiveFacts::PresenceConstraint === c &&
	  #     ActiveFacts::ValueType === c.object_type
	  @out.puts "\t"+c.to_s
	}
      @out.puts " */" if heading
    end
  end

  class Model
    def dump(out = $>)
      CQLDumper.new(self).dump(out)
    end
  end
end

