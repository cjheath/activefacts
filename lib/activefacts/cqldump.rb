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
      @out.puts "vocabulary #{@model.name};\n\n"

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
      @out.puts "/*\n * Value Types\n */"
      @model.object_types.sort_by{|o| o.name}.each{|o|
	  next if EntityType === o
	  if o.name == o.data_type.name
	      # In ActiveFacts, parameterising a ValueType will create a new datatype
	      # throw Can't handle parameterized value type of same name as its datatype" if ...
	  end

	  @out.puts "#{o.to_s};"
	}
    end

    def fact_readings_with_constraints(fact_type)
      define_role_names = true
      fact_constraints = @set_constraints_by_fact[fact_type].clone
      readings = fact_type.readings.map{|r|
	  # Find relevant PresenceConstraints
	  # Find all role numbers in order of occurrence:
	  roles = r.name.scan(/\{(\d)\}/).flatten.map{|m| r.role_sequence[Integer(m)] }

	  # Build a hash of presence constraints keyed by the residual (uncovered) role:
	  expand_using = fact_type.all_presence_constraints_by_uncovered_role(fact_constraints)

	  constraints = expand_using.values

	  # expand() will delete from the hash any constraints it could verbalise:
	  s = r.expand(expand_using, define_role_names)

	  unverbalised_constraints = constraints-expand_using.values
	  fact_constraints -= unverbalised_constraints
	  unverbalised_constraints.each{|c|
	      @constraints_used[c] = true
	    }
	  define_role_names = false	# No need to define role names in subsequent readings
	  s
	}
      if fact_constraints.size == 0
	# We've exhausted the set constraints on this fact type.
	@fact_set_constraints_exhausted[fact_type] = true
      end
      readings
    end

    def known_by(o, pi)
      # REVISIT: Need to include adjectives here:
      identifying_roles = pi.role_sequence.map{|r| r.role_name }*" and "

      identifying_facts = pi.role_sequence.map{|r| r.fact_type }.uniq
      #pp identifying_facts.map{|f| f.preferred_reading }
      " known by #{ identifying_roles }:\n\t" +
      # REVISIT: Consider emitting all fact types we can, not just identifying ones?
	  identifying_facts.map{|f|
	      fact_readings_with_constraints(f)
	  }.flatten*",\n\t"
    end

    def dump_entity_type(o)
      pi = o.preferred_identifier
      @constraints_used[pi] = true

      if (supertype = o.primary_supertype)
	spi = o.primary_supertype.preferred_identifier
	@out.puts "#{o.name} = subtype of #{ o.supertypes.map(&:name)*", " }" +
	  (pi != spi ? known_by(o, pi) : "") +
	  ";\n\n"
      else
	@out.puts "#{o.name} = entity" +
	  known_by(o, pi) +
	  ";\n\n"
      end
    end

    def dump_entity_types
      @out.puts "\n/*\n * Entity Types\n */"
      # Try to dump entity types in order of name, but we need
      # to dump ETs before they're referenced in preferred ids
      # if possible (it's not always, there may be loops!)
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
		(precursor[o] ||= []) << player if (player != o)
		(follower[player] ||= []) << o if (player != o)
	      }
	    # Supertypes are precursors too:
	    o.subtypes.each{|s|
		(precursor[s] ||= []) << o
		(follower[o] ||= []) << s
	      }
	  end
	  a
	}

      sorted = @model.object_types.sort_by{|o| o.name}
      done = {}
      panic = nil
      while entity_count > 0 do
	count_this_pass = 0
	sorted.each{|o|
	    next unless EntityType === o && !done[o]	# Not an ET or already done
	    # precursors[o] -= [o] if precursors[o]

	    next if (o != panic && (p = precursors[o]) && p.size > 0)	# Not yet, still blocked

	    # We're going to emit o - remove it from precursors of others:
	    (followers[o]||[]).each{|f|
		precursors[f] -= [o]
	      }
	    entity_count -= 1
	    count_this_pass += 1
	    done[o] = true
	    panic = nil

	    dump_entity_type(o)
	  }

	  # Check that we made progress:
	  if count_this_pass == 0 && entity_count > 0
	    if panic
	      # This won't happen again unless the above code is changed to decide it can't dump "panic".
	      raise "Unresolvable cycle of forward references: " +
		(bad = sorted.select{|o| EntityType === o && !done[o]}).map{|o| o.name }.inspect +
		":\n\t" + bad.map{|o|
		  o.name +
		  ": " +
		  precursors[o].map{|p| p.name}.uniq.inspect
		} * "\n\t" + "\n"
	    else
	      # Find the object that has the most followers and no fwd-ref'd supertypes:
	      panic = sorted.
		select{|o| !done[o] }.
		sort_by{|o|
		    f = followers[o] || []; 
		    o.supertypes.detect{|s| !done[s] } ? 0 : -f.size
		  }[0]
	      # puts "Panic mode, selected #{panic.name} next"
	    end
	  end

      end
    end

    # Dump fact types.
    # Include as many as possible internal presence constraints in the fact type readings.
    def dump_fact_types
      # REVISIT: Mandatory on the LHS of a binary can be coded using "every"
      # REVISIT: Uniqueness on the LHS of a binary can be coded using "distinct"

      @out.puts "\n/*\n * Fact Types\n */"
      @model.fact_types.each{|f|
	  # REVISIT: There might be constraints we have to merge into the nested entity or subtype. 
	  # These will come up as un-handled constraints
	  next if f.nested_as ||
	    @fact_set_constraints_exhausted[f] ||
	    SubtypeFactType === f

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

	  # Skip some PresenceConstraints:
	  if ActiveFacts::PresenceConstraint === c
	    # Skip uniqueness constraints that cover all roles of a fact type, they're implicit
	    next if c.max == 1 &&	    # Uniqueness
	      c.role_sequence.size == c.role_sequence[0].fact_type.roles.size &&	# Same number of roles
	      c.role_sequence[0].fact_type.roles.all?{|r| c.role_sequence.include? r}	# All present

	    # Skip internal PresenceConstraints over SubtypeFactTypes:
	    next if SubtypeFactType === c.role_sequence[0].fact_type &&
	      !c.role_sequence.detect{|r| r.fact_type != c.role_sequence[0].fact_type }
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

