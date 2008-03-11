#
# Dump to CQL module for ActiveFacts vocabularies.
#
# Adds the Vocabulary.dump_cql() method.
#
# Copyright (c) 2007 Clifford Heath. Read the LICENSE file.
# Author: Clifford Heath.
#
module ActiveFacts

  class CQLDumper
    def initialize(vocabulary)
      @vocabulary = vocabulary
    end

    def dump(out = $>)
      @out = out
      @out.puts "vocabulary #{@vocabulary.name};\n\n"

      build_indices
      @concept_types_dumped = {}
      @fact_types_dumped = {}
      dump_value_types()
      dump_entity_types()
      dump_fact_types()
      dump_constraints(@constraints_used)
    end

    def build_indices
      @set_constraints_by_fact = Hash.new{ |h, k| h[k] = [] }
      @ring_constraints_by_fact = Hash.new{ |h, k| h[k] = [] }

      @vocabulary.constraints.each { |c|
	  case c
	  when SetConstraint
	    fact_types = c.role_sequence.map(&:fact_type).uniq	# All fact types spanned by this constraint
	    if fact_types.size == 1	# There's only one, save it:
	      # $stderr.puts "Single-fact constraint on #{fact_types[0].name}: #{c.name}"
	      (@set_constraints_by_fact[fact_types[0]] ||= []) << c
	    end
	  when RingConstraint
	    (@ring_constraints_by_fact[c.from_role.fact_type] ||= []) << c
	  else
	    #puts "Found unhandled #{c.class} #{c.name}"
	  end
	}
      @constraints_used = {}
      @fact_set_constraints_exhausted = {}
    end

    def dump_value_types
      @out.puts "/*\n * Value Types\n */"
      @vocabulary.concepts.sort_by{|o| o.name}.each{|o|
	  next if EntityType === o
	  dump_value_type(o)
	  @concept_types_dumped[o] = true
	}
    end

    def dump_value_type(o)
      if o.name == o.data_type.name
	  # In ActiveFacts, parameterising a ValueType will create a new datatype
	  # throw Can't handle parameterized value type of same name as its datatype" if ...
      end

      @out.puts "#{o.to_s};"
    end

    def fact_readings_with_constraints(fact_type)
      define_role_names = true
      fact_constraints = @set_constraints_by_fact[fact_type]
      used_constraints = []
      readings = fact_type.readings.inject([]){|reading_array, reading|
	  # Find all role numbers in order of occurrence in this reading:
	  roles = reading.name.scan(/\{(\d)\}/).flatten.map{|m| reading.role_sequence[Integer(m)] }

	  # Find the frequencies that constraints imply over each role we can verbalise:
	  frequencies = []
	  role_mandatory_but_not_unique = []
	  roles.each {|role|
	      # Find a mandatory constraint that's *not* unique; this will need an extra reading
	      role_is_first_in = fact_type.readings.detect{|r| r.role_sequence[0] == role }

	      role_mandatory_but_not_unique <<
		(
		  (!role_is_first_in || role_is_first_in == reading) &&
		  fact_constraints.find{|c|
		      PresenceConstraint === c &&
		      c.is_mandatory &&
		      (!c.max || c.max > 1) &&
		      c.role_sequence == [role] &&
		      !@constraints_used[c]	# Already verbalised
		    }
		)

	      if (role != roles[0])   # First role of the reading?
		# REVISIT: With a ternary, doing this on other than the last role can be ambiguous,
		# in case both the 2nd and 3rd roles have frequencies. Think some more!

		constraint = fact_constraints.find{|c|	# Find a UC that spans all other Roles
		    # internal uniqueness constraints span all roles but one, the residual:
		    PresenceConstraint === c &&
		      !@constraints_used[c] &&	# Already verbalised
		      roles-c.role_sequence == [role]
		  }
		# Index the frequency implied by the constraint under the role position in the reading
		if constraint	  # Mark this constraint as "verbalised" so we don't do it again:
		  @constraints_used[constraint] = true
		  used_constraints << constraint
		end
		frequencies << (constraint ? constraint.frequency : nil)
	      else
		frequencies << nil
	      end
	    }

	  reading_array << reading.expand(frequencies, define_role_names)

	  if (ft_rings = @ring_constraints_by_fact[fact_type]) &&
	     (ring = ft_rings.detect{|rc| !@constraints_used[rc]})
	    @constraints_used[ring] = true
	    used_constraints << ring
	    reading_array[-1] << " [#{ring.type_name}]"
	  end

	  define_role_names = false	# No need to define role names in subsequent readings

	  # If the first Role is mandatory but not unique, and we haven't absorbed this
	  # mandation into a uniqueness constraint, we need to re-iterate this reading by
	  # saying "each X has some Y for some Z"
	  role_mandatory_but_not_unique.each_with_index{|mc, i|
	      next unless mc
	      frequencies = [ "some" ]*i + [ "each" ] + [ "some" ]*(roles.size-i-1)
	      reading_array << reading.expand(frequencies, false)

	      # REVISIT: If min > 1 (a frequency constraint), this constraint isn't fully verbalised
#	      if first_role_mandatory.min == 1
		@constraints_used[mc] = true
		used_constraints << mc
#	      end
	    }

	  reading_array
	}
      #puts "Used #{fact_constraints_used} of #{used_constraints.uniq.size} constraints over #{fact_type.name}"
      if (fact_constraints-used_constraints).size == 0
	# We've exhausted the set constraints on this fact type.
	@fact_set_constraints_exhausted[fact_type] = true
      end
      readings
    end

    def known_by(o, pi)
      identifying_roles = pi.role_sequence.map{|r| r.role_name }*" and "

      identifying_facts = pi.role_sequence.map{|r| r.fact_type }.uniq
      #p identifying_facts.map{|f| f.preferred_reading }

      # REVISIT: Consider emitting extra fact types here, instead of in dump_entity_type?
      # Just beware that readings having the same players will be considered to be of the same fact type, even if they're not.

      " known by #{ identifying_roles }:\n\t" +
	  identifying_facts.map{|f|
	      fact_readings_with_constraints(f)
	  }.flatten*",\n\t"
    end

    def dump_entity_type(o)
      pi = o.preferred_identifier

      if (supertype = o.primary_supertype)
	spi = o.primary_supertype.preferred_identifier
	@out.puts "#{o.name} = subtype of #{ o.supertypes.map(&:name)*", " }" +
	  (pi != spi ? known_by(o, pi) : "") +
	  ";\n"
      else
	@out.puts "#{o.name} = entity" +
	  known_by(o, pi) +
	  ";\n"
      end
      @constraints_used[pi] = true
    end

    # Try to dump entity types in order of name, but we need
    # to dump ETs before they're referenced in preferred ids
    # if possible (it's not always, there may be loops!)
    def dump_entity_types
      @out.puts "\n/*\n * Entity Types\n */"
      # Build hash tables of precursors and followers to use:
      entity_count = 0
      precursors, followers = *@vocabulary.concepts.inject([{},{}]) { |a, o|
	  if EntityType === o
	    entity_count += 1
	    precursor = a[0]
	    follower = a[1]
	    blocked = false
	    pi = o.preferred_identifier
	    if pi
	      pi.role_sequence.each{|r|
		  player = r.concept
		  next unless EntityType === player
		  # player is a precursor of o
		  (precursor[o] ||= []) << player if (player != o)
		  (follower[player] ||= []) << o if (player != o)
		}
	    end
	    # Supertypes are precursors too:
	    o.subtypes.each{|s|
		(precursor[s] ||= []) << o
		(follower[o] ||= []) << s
	      }
	  end
	  a
	}

      sorted = @vocabulary.concepts.sort_by{|o| o.name}
      panic = nil
      while entity_count > 0 do
	count_this_pass = 0
	sorted.each{|o|
	    next unless EntityType === o && !@concept_types_dumped[o]	# Not an ET or already done
	    # precursors[o] -= [o] if precursors[o]

	    next if (o != panic && (p = precursors[o]) && p.size > 0)	# Not yet, still blocked

	    # We're going to emit o - remove it from precursors of others:
	    (followers[o]||[]).each{|f|
		precursors[f] -= [o]
	      }
	    entity_count -= 1
	    count_this_pass += 1
	    @concept_types_dumped[o] = true
	    panic = nil

	    dump_entity_type(o)
	    o.roles.map(&:fact_type).uniq.select{|f|
		# The fact type hasn't already been dumped but all its role players have
		!@fact_types_dumped[f] &&
		!f.roles.detect{|r| !@concept_types_dumped[r.concept] }
	      }.each{|f|
		  dump_fact_type(f)
		}
	    @out.puts "\n"
	  }

	  # Check that we made progress:
	  if count_this_pass == 0 && entity_count > 0
	    if panic
	      # This won't happen again unless the above code is changed to decide it can't dump "panic".
	      raise "Unresolvable cycle of forward references: " +
		(bad = sorted.select{|o| EntityType === o && !@concept_types_dumped[o]}).map{|o| o.name }.inspect +
		":\n\t" + bad.map{|o|
		  o.name +
		  ": " +
		  precursors[o].map{|p| p.name}.uniq.inspect
		} * "\n\t" + "\n"
	    else
	      # Find the object that has the most followers and no fwd-ref'd supertypes:
	      panic = sorted.
		select{|o| !@concept_types_dumped[o] }.
		sort_by{|o|
		    f = followers[o] || []; 
		    o.supertypes.detect{|s| !@concept_types_dumped[s] } ? 0 : -f.size
		  }[0]
	      # puts "Panic mode, selected #{panic.name} next"
	    end
	  end

      end
    end

    def skip_fact_type(f)
      # REVISIT: There might be constraints we have to merge into the nested entity or subtype. 
      # These will come up as un-handled constraints:
      f.nested_as ||
	@fact_set_constraints_exhausted[f] ||
	TypeInheritance === f
    end

    # Dump one fact type.
    # Include as many as possible internal constraints in the fact type readings.
    def dump_fact_type(f)
      return if skip_fact_type(f)

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

      @fact_types_dumped[f] = true
    end

    # Dump fact types.
    def dump_fact_types
      # REVISIT: Uniqueness on the LHS of a binary can be coded using "distinct"

      done_banner = false
      @vocabulary.fact_types.each{|f|
	  next if @fact_types_dumped[f] || skip_fact_type(f)

	  @out.puts "/*\n * Fact Types\n */" unless done_banner
	  done_banner = true
	  dump_fact_type(f)
	}
      @out.puts "\n" if done_banner
      # unused = constraints - @constraints_used.keys
      # $stderr.puts "residual constraints are\n\t#{unused.map(&:to_s)*",\n\t"}"

      @constraints_used
    end

    def dump_fact_instances
      @vocabulary.fact_types.each{|f|
	  # Dump the instances:
	  f.facts.each{|i|
	    @out.puts "\t\t"+i.to_s
	  }
      }
    end

    def dump_constraints(except = {})
      heading = false
      @vocabulary.constraints.sort_by{|c| c.name}.each{|c|
	  next if except[c]

	  # Skip some PresenceConstraints:
	  if ActiveFacts::PresenceConstraint === c
	    # Skip uniqueness constraints that cover all roles of a fact type, they're implicit
	    next if c.max == 1 &&	    # Uniqueness
	      c.role_sequence.size == c.role_sequence[0].fact_type.roles.size &&	# Same number of roles
	      c.role_sequence[0].fact_type.roles.all?{|r| c.role_sequence.include? r}	# All present

	    # Skip internal PresenceConstraints over TypeInheritances:
	    next if TypeInheritance === c.role_sequence[0].fact_type &&
	      !c.role_sequence.detect{|r| r.fact_type != c.role_sequence[0].fact_type }
	  end

	  unless heading
	    @out.puts "/*\nConstraints:"
	    heading = true
	  end

	  # Skip presence constraints on value types:
	  # next if ActiveFacts::PresenceConstraint === c &&
	  #     ActiveFacts::ValueType === c.concept
	  @out.puts "\t"+c.to_s
	}
      @out.puts " */" if heading
    end
  end

  class Vocabulary
    def dump(out = $>)
      CQLDumper.new(self).dump(out)
    end
  end
end

