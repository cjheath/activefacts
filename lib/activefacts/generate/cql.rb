#
# Dump to CQL module for ActiveFacts vocabularies.
#
# Copyright (c) 2007 Clifford Heath. Read the LICENSE file.
# Author: Clifford Heath.
#
module ActiveFacts
  class Constellation; end

  class CQLDumper
    include Metamodel

    def initialize(vocabulary)
      @vocabulary = vocabulary
    end

    def dump(out = $>)
      @vocabulary = @vocabulary.Vocabulary[0] if ActiveFacts::Constellation === @vocabulary
      @out = out
      @out.puts "vocabulary #{@vocabulary.name};\n\n"

      build_indices
      @concept_types_dumped = {}
      @fact_types_dumped = {}
      value_types_dump()
      entity_types_dump()
      fact_types_dump()
      constraints_dump(@constraints_used)

    end

    def build_indices
      @presence_constraints_by_fact = Hash.new{ |h, k| h[k] = [] }
      @ring_constraints_by_fact = Hash.new{ |h, k| h[k] = [] }

      @vocabulary.all_constraint.each { |c|
	  case c
	  when PresenceConstraint
	    fact_types = c.role_sequence.all_role_ref.map{|rr| rr.role.fact_type}.uniq	# All fact types spanned by this constraint
	    if fact_types.size == 1	# There's only one, save it:
	      #puts "Single-fact constraint on #{fact_types[0].fact_type_id}: #{c.name}"
	      (@presence_constraints_by_fact[fact_types[0]] ||= []) << c
	    end
	  when RingConstraint
	    (@ring_constraints_by_fact[c.role.fact_type] ||= []) << c
	  else
	    #puts "Found unhandled #{c.class} #{c.name}"
	  end
	}
      @constraints_used = {}
      @fact_set_constraints_exhausted = {}
    end

    def value_types_dump
      done_banner = false
      @vocabulary.all_feature.sort_by{|o| o.name}.each{|o|
	  next if EntityType === o

	  @out.puts "/*\n * Value Types\n */" unless done_banner
	  done_banner = true

	  value_type_dump(o)
	  @concept_types_dumped[o] = true
	}
      @out.puts "\n" if done_banner
    end

    def value_type_dump(o)
      return unless o.supertype    # An imported type
      if o.name == o.supertype.name
	  # In ActiveFacts, parameterising a ValueType will create a new datatype
	  # throw Can't handle parameterized value type of same name as its datatype" if ...
      end

      parameters =
	[ o.length != 0 || o.scale != 0 ? o.length : nil,
	  o.scale != 0 ? o.scale : nil
	].compact
      parameters = parameters.length > 0 ? "("+parameters.join(",")+")" : "()"

		#" restricted to {#{(allowed_values.map{|r| r.inspect}*", ").gsub('"',"'")}}")

      @out.puts "#{o.name} = #{o.supertype.name}#{ parameters }#{
	  o.value_restriction ? " restricted to {#{
	    o.value_restriction.all_allowed_range.map{|ar|
		# REVISIT: Need to display as string or numeric according to type here...
		min = ar.value_range.minimum_bound
		max = ar.value_range.maximum_bound
		(min ? min.value : "") +
		(min.value != max.value ? (".." + (max ? max.value : "")) : "")
	      }*", "
	  }}" : ""
	};"
    end

    def expand_reading(reading, frequencies, define_role_names)
      expanded = "#{reading.reading_text}"
      role_refs = reading.role_sequence.all_role_ref.sort_by{|role_ref| role_ref.ordinal}
      (0...role_refs.size).each{|i|
	  role_ref = role_refs[i]
	  role = role_ref.role
	  la = "#{role_ref.leading_adjective}"
	  la.sub!(/(.\b|.\Z)/, '\1-')
	  la = nil if la == ""
	  ta = "#{role_ref.trailing_adjective}"
	  ta.sub!(/(\b.|\A.)/, '-\1')
	  ta = nil if ta == ""

	  expanded.gsub!(/\{#{i}\}/) {
	      player = role_refs[i].role.concept
	      role_name = role.role_name
	      role_name = nil if role_name == ""
	      [
		frequencies[i],
		la,
		!define_role_names && role_name ? role_name : player.name,
		ta,
		define_role_names && role_name && player.name != role_name ? "(as #{role_name})" : nil
	      ].compact*" "
	  }
      }
      expanded.gsub!(/ *- */, '-')	# Remove spaces around adjectives
      expanded
    end

    def presence_constraint_frequency(constraint)
      min = constraint.min_frequency
      max = constraint.max_frequency
      [
	  ((min && min > 0 && min != max) ? "at least #{min == 1 ? "one" : min.to_s}" : nil),
	  ((max && min != max) ? "at most #{max == 1 ? "one" : max.to_s}" : nil),
	  ((max && min == max) ? "exactly #{max == 1 ? "one" : max.to_s}" : nil)
      ].compact * " and"
    end

    def fact_readings_with_constraints(fact_type)
      define_role_names = true
      fact_constraints = @presence_constraints_by_fact[fact_type]
      used_constraints = []
      readings = all_reading_by_ordinal(fact_type).inject([]){|reading_array, reading|
	  # Find all role numbers in order of occurrence in this reading:
	  role_refs = reading.role_sequence.all_role_ref.sort_by{|role_ref| role_ref.ordinal}
	  role_numbers = reading.reading_text.scan(/\{(\d)\}/).flatten.map{|m| Integer(m) }
	  roles = role_numbers.map{|m| role_refs[m].role }
	  # puts "Considering #{reading.reading_text} having #{role_numbers.inspect}"

	  # Find the frequencies that constraints imply over each role we can verbalise:
	  frequencies = []
	  role_mandatory_but_not_unique = []
	  roles.each {|role|
	      # Find a mandatory constraint that's *not* unique; this will need an extra reading
	      role_is_first_in = fact_type.all_reading.detect{|r|
		  role == r.role_sequence.all_role_ref.sort_by{|role_ref|
		      role_ref.ordinal
		    }[0].role
		}

	      role_mandatory_but_not_unique <<
		(
		  (!role_is_first_in || role_is_first_in == reading) &&
		  fact_constraints.find{|c|
		      PresenceConstraint === c &&
		      c.is_mandatory &&
		      (!c.max_frequency || c.max_frequency > 1) &&
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
		      roles-c.role_sequence.all_role_ref.map(&:role) == [role]
		  }
		# Index the frequency implied by the constraint under the role position in the reading
		if constraint	  # Mark this constraint as "verbalised" so we don't do it again:
		  @constraints_used[constraint] = true
		  used_constraints << constraint
		end
		frequencies << (constraint ? presence_constraint_frequency(constraint) : nil)
	      else
		frequencies << nil
	      end
	    }

	  reading_array << expand_reading(reading, frequencies, define_role_names)

	  if (ft_rings = @ring_constraints_by_fact[fact_type]) &&
	     (ring = ft_rings.detect{|rc| !@constraints_used[rc]})
	    @constraints_used[ring] = true
	    used_constraints << ring
	    reading_array[-1] << " [#{(ring.ring_type.scan(/[A-Z][a-z]*/)*", ").downcase}]"
	  end

	  define_role_names = false	# No need to define role names in subsequent readings

	  # If the first Role is mandatory but not unique, and we haven't absorbed this
	  # mandation into a uniqueness constraint, we need to re-iterate this reading by
	  # saying "each X has some Y for some Z"
	  role_mandatory_but_not_unique.each_with_index{|mc, i|
	      next unless mc
	      raise "REVISIT: Not yet reimplemented"
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

    def identified_by(o, pi)
      # REVISIT: Different adjectives might be used for different readings.
      # Here, we must find the role_ref containing the adjectives that we need for each identifier,
      # which will be attached to the uniqueness constraint on this object in the binary FT that
      # attaches that identifying role.
      role_refs = pi.role_sequence.all_role_ref.sort_by{|role_ref| role_ref.ordinal}

      # We need to get the adjectives for the roles from the identifying fact's preferred readings:
      identifying_facts = role_refs.map{|rr| rr.role.fact_type }.uniq
      preferred_readings = identifying_facts.inject({}){|reading_hash, fact_type|
	  reading_hash[fact_type] = preferred_reading(fact_type)
	  reading_hash
	}
      #p identifying_facts.map{|f| f.preferred_reading }

      identifying_role_names = role_refs.map{|role_ref|
	  role = role_ref.role
	  # role.concept.name
	  preferred_role_ref = preferred_readings[role.fact_type].role_sequence.all_role_ref.detect{|reading_rr|
	      reading_rr.role == role
	    }
	  role_words = []
	  role_words << preferred_role_ref.leading_adjective if preferred_role_ref.leading_adjective != ""

	  role_name = role_ref.role.role_name
	  role_name = nil if role_name == ""
	  #$stderr.puts "concept.name=#{preferred_role_ref.role.concept.name}, role_name=#{role_name.inspect}, preferred_role_name=#{preferred_role_ref.role.role_name.inspect}"

	  role_words << (role_name || preferred_role_ref.role.concept.name)
	  role_words << preferred_role_ref.trailing_adjective if preferred_role_ref.trailing_adjective != ""
	  role_words*"-"
	}

      # REVISIT: Consider emitting extra fact types here, instead of in entity_type_dump?
      # Just beware that readings having the same players will be considered to be of the same fact type, even if they're not.

      " identified by #{ identifying_role_names*" and " }:\n\t" +
	  identifying_facts.map{|f|
	      fact_readings_with_constraints(f)
	  }.flatten*",\n\t"
    end

    def preferred_reading(fact_type)
      all_reading_by_ordinal(fact_type)[0]
    end

    def all_reading_by_ordinal(fact_type)
      fact_type.all_reading.sort_by{|reading| reading.ordinal}
    end

    def entity_type_dump(o)
      @concept_types_dumped[o] = true
      pi = preferred_identifier(o)

      if (supertype = primary_supertype(o))
	spi = preferred_identifier(supertype)
	@out.puts "#{o.name} = subtype of #{ supertypes(o).map(&:name)*", " }" +
	  (pi != spi ? identified_by(o, pi) : "") +
	  ";\n"
      else
	@out.puts "#{o.name} = entity" +
	  identified_by(o, pi) +
	  ";\n"
      end
      @constraints_used[pi] = true
    end

    # An array all direct supertypes
    def supertypes(o)
	o.all_type_inheritance.map{|ti|
	    ti.super_entity_type
	  }
    end

    # An array of self followed by all supertypes in order:
    def supertypes_transitive(o)
	([o] + o.all_type_inheritance.map{|ti|
	    #puts ti.class.roles.verbalise; exit
	    supertypes_transitive(ti.super_entity_type)
	  }).flatten.uniq
    end

    def preferred_identifier(o)
      if o.fact_type
	# For a nested fact type, the PI is a unique constraint over N or N-1 roles
	o.fact_type.all_role

	fact_roles = o.fact_type.all_role
	# $stderr.puts "Looking for PI on nested fact type #{o.name}"
	pi = catch :pi do
	    fact_roles.each{|r|			# Try all roles of the fact type
		r.all_role_ref.map{|rr|		# All role sequences that reference this role
		    role_sequence = rr.role_sequence

		    # The role sequence is only interesting if it cover only this fact's roles
		    next if role_sequence.all_role_ref.size < fact_roles.size-1
		    next if role_sequence.all_role_ref.size > fact_roles.size
		    next if role_sequence.all_role_ref.detect{|rsr| !(ft = rsr.role.fact_type) || ft != o.fact_type }

		    # This role sequence is a candidate
		    pc = role_sequence.all_presence_constraint.detect{|c|
			c.is_preferred_identifier
		      }
		    throw :pi, pc if pc
		  }
	      }
	    throw :pi, nil
	  end
	# $stderr.puts "Got PI #{pi.name} for nested #{o.name}" if pi
	# $stderr.puts "Looking for PI on entity that nests this fact" unless pi
	raise "Oops, pi for nested fact is #{pi.class}" unless !pi || PresenceConstraint === pi
	return pi if pi
      end

      # $stderr.puts "\nLooking for PI for ordinary entity #{o.name} with #{o.all_role.size} roles:"
      # $stderr.puts "Roles are in #{o.all_role.map{|r| describe_fact_type(r.fact_type, r)}*", "})"
      pi = catch :pi do
	  all_supertypes = supertypes_transitive(o)
	  # $stderr.puts "PI roles must be played by one of #{all_supertypes.map(&:name)*", "}" if all_supertypes.size > 1
	  o.all_role.each{|role|
	      ftroles = role.fact_type.all_role
	      next if ftroles.size > 2	# Skip roles in objectified fact types

	      # $stderr.puts "Considering role in #{describe_fact_type(role.fact_type, role)}"

	      # Find the related role which must be included in any PI:
	      # Note this works with unary fact types:
	      pi_role = ftroles.size == 1 || ftroles[1] == role ? ftroles[0] : ftroles[1]

	      next if ftroles.size == 2 && pi_role.concept == o
	      # $stderr.puts "\tConsidering #{pi_role.concept.name} as a PI role"

	      # Look in all role sequences that include this related role
	      pi_role.all_role_ref.each{|rr|
		  role_sequence = rr.role_sequence  # A role sequence that includes a possible role
		  # $stderr.puts "\t\tConsidering role sequence #{describe_role_sequence(role_sequence)}"

		  # All roles in this role_sequence to fact types
		  # which (apart from that role) only have roles
		  # played by the original entity type or a supertype.
		  next if role_sequence.all_role_ref.detect{|rsr|
		      fact_type_roles = rsr.role.fact_type.all_role
		      residual_roles = fact_type_roles-[rsr.role]
		      residual_roles.detect{|rfr|
			  !all_supertypes.include?(rfr.concept)
			}
		    }

		  # Any presence constraint over this role sequence is a candidate
		  rr.role_sequence.all_presence_constraint.detect{|pc|
		      # Found it!
		      if pc.is_preferred_identifier
			# $stderr.puts "found PI #{pc.name}, is_preferred_identifier=#{pc.is_preferred_identifier.inspect}, enforcement=#{pc.enforcement}"
			throw :pi, pc
		      end
		    }
		}
	    }
	  throw :pi, nil
	end
      raise "Oops, pi for entity is #{pi.class}" if pi && !(PresenceConstraint === pi)
      # $stderr.puts "Got PI #{pi.name} for #{o.name}" if pi

      if !pi && (supertype = primary_supertype(o))
	# $stderr.puts "PI not found for #{o.name}, looking in supertype #{supertype.name}"
	pi = preferred_identifier(supertype)
      else
	# $stderr.puts "No PI found for #{o.name}" if !pi
      end
      raise "No PI found for #{o.name}" unless pi
      pi
    end

    def describe_fact_type(fact_type, highlight = nil)
      (fact_type.entity_type ? fact_type.entity_type.name : "")+
      describe_roles(fact_type.all_role, highlight)
    end

    def describe_roles(roles, highlight = nil)
      "("+
      roles.map{|role| role.concept.name + (role == highlight ? "*" : "")}*", "+
      ")"
    end

    def describe_role_sequence(role_sequence)
      "("+
      role_sequence.all_role_ref.map{|role_ref| role_ref.role.concept.name }*", "+
      ")"
    end

    def primary_supertype(o)
      o.all_type_inheritance.detect{|ti|
	  return ti.super_entity_type if ti.defines_primary_supertype
	}
      return nil
    end

    # This returns an array of two hash tables each keyed by an EntityType.
    # The values of each hash entry are the precursors and followers (respectively) of that entity.
    def build_entity_dependencies
      @vocabulary.all_feature.inject([{},{}]) { |a, o|
	  if EntityType === o && !o.fact_type
	    precursor = a[0]
	    follower = a[1]
	    blocked = false
	    pi = preferred_identifier(o)
	    if pi
	      pi.role_sequence.all_role_ref.each{|rr|
		  role = rr.role
		  player = role.concept
		  next unless EntityType === player
		  # player is a precursor of o
		  (precursor[o] ||= []) << player if (player != o)
		  (follower[player] ||= []) << o if (player != o)
		}
	    end
	    # Supertypes are precursors too:
	    subtypes = o.all_type_inheritance_by_super_entity_type
	    next a if subtypes.size == 0
	    o.all_type_inheritance_by_super_entity_type.each{|ti|
		#puts ti.class.roles.verbalise; puts "all_type_inheritance_by_super_entity_type"; exit
		s = ti.entity_type
		(precursor[s] ||= []) << o
		(follower[o] ||= []) << s
	      }
	  end
	  a
	}
    end

    # Try to dump entity types in order of name, but we need
    # to dump ETs before they're referenced in preferred ids
    # if possible (it's not always, there may be loops!)
    def entity_types_dump
      # Build hash tables of precursors and followers to use:
      precursors, followers = *build_entity_dependencies

      done_banner = false
      sorted = @vocabulary.all_feature.select{|o| EntityType === o and !o.fact_type }.sort_by{|o| o.name}
      panic = nil
      while true do
	count_this_pass = 0
	skipped_this_pass = 0
	sorted.each{|o|
	    next if @concept_types_dumped[o]	# Already done

	    # Can we do this yet?
	    if (o != panic and			# We don't *have* to do it (panic mode)
		(p = precursors[o]) and		# There might be...
		p.size > 0)			# precursors - still blocked
	      skipped_this_pass += 1
	      next
	    end

	    @out.puts "/*\n * Entity Types\n */" unless done_banner
	    done_banner = true

	    # We're going to emit o - remove it from precursors of others:
	    (followers[o]||[]).each{|f|
		precursors[f] -= [o]
	      }
	    count_this_pass += 1
	    panic = nil

	    entity_type_dump(o)

	    released_fact_types_dump(o)

	    @out.puts "\n"
	  }

	  # Check that we made progress if there's any to make:
	  if count_this_pass == 0 && skipped_this_pass > 0
	    if panic	    # We were already panicing... what to do now?
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
	      # This selection might be better if we allow PI roles to be fwd-ref'd...
	      panic = sorted.
		select{|o| !@concept_types_dumped[o] }.
		sort_by{|o|
		    f = followers[o] || []; 
		    supertypes(o).detect{|s| !@concept_types_dumped[s] } ? 0 : -f.size
		  }[0]
	      # puts "Panic mode, selected #{panic.name} next"
	    end
	  end

	  break if skipped_this_pass == 0	# All done.

      end
    end

    # Dump all fact types for which all precursors (of which "o" is one) have been emitted:
    def released_fact_types_dump(o)
      roles = o.all_role
      begin
	progress = false
	roles.map(&:fact_type).uniq.select{|fact_type|
	    # The fact type hasn't already been dumped but all its role players have
	    !@fact_types_dumped[fact_type] &&
	      !fact_type.all_role.detect{|r| !@concept_types_dumped[r.concept] }
	  }.each{|fact_type|
	      fact_type_dump(fact_type)
	      # Objectified Fact Types may release additional fact types
	      roles += fact_type.entity_type.all_role if fact_type.entity_type
	      progress = true
	    }
      end while progress
    end

    def skip_fact_type(f)
      # REVISIT: There might be constraints we have to merge into the nested entity or subtype. 
      # These will come up as un-handled constraints:
      @fact_set_constraints_exhausted[f] ||
	TypeInheritance === f
    end

    # Dump one fact type.
    # Include as many as possible internal constraints in the fact type readings.
    def fact_type_dump(fact_type)
      @fact_types_dumped[fact_type] = true
      # puts "Trying to dump FT again" if @fact_types_dumped[fact_type]
      return if skip_fact_type(fact_type)

      if (et = fact_type.entity_type) &&
	  (pi = preferred_identifier(et)) &&
	  pi.role_sequence.all_role_ref[0].role.fact_type != fact_type
	# puts "Dumping objectified FT #{et.name} as an entity, non-fact PI"
	# REVISIT: Need to find a way to dump a fact type with non-fact type PI
	entity_type_dump(et)
	released_fact_types_dump(et)
	return
      end

      fact_constraints = @presence_constraints_by_fact[fact_type]

      # $stderr.puts "for fact type #{fact_type.to_s}, considering\n\t#{fact_constraints.map(&:to_s)*",\n\t"}"
      # $stderr.puts "#{fact_type.name} has readings:\n\t#{fact_type.readings.map(&:name)*"\n\t"}"
#puts "Dumping #{fact_type.fact_type_id} as a fact type"

      # Omit fact type names from fact types that aren't implicitly nested
      # We've already skipped explicitly nested fact types.
      # REVISIT: This should be a method on the fact type
      name = (fact_type.entity_type ? fact_type.entity_type.name+" = " : "")
#      name = "" unless fact_constraints.detect{|c|
#	  PresenceConstraint === c &&
#	  c.role_sequence.size > 1
#	}
      @out.puts name +
	fact_readings_with_constraints(fact_type)*",\n\t" +
	";"
      # REVISIT: Go through the residual constraints and re-process appropriate readings to show them

      @fact_types_dumped[fact_type] = true
      @concept_types_dumped[fact_type.entity_type] = true if fact_type.entity_type
    end

    # Dump fact types.
    def fact_types_dump
      # REVISIT: Uniqueness on the LHS of a binary can be coded using "distinct"

      # The only fact types tht can be remaining are those involving only value types,
      # since we dumped every fact type as soon as all relevant entities were dumped.
      # Iterate over all fact types of all value types, looking for these strays.

      done_banner = false
      @vocabulary.constellation.FactType.each{|fact_type|
#      @vocabulary.all_feature.each{|f|
#	  next unless ValueType === f
#	  #puts "Considering ValueType #{f.name}"
#	  f.all_role.each{|role|
#	      #puts "\tConsidering Role #{role.verbalise}"
#	      fact_type = role.fact_type
	      next if @fact_types_dumped[fact_type] || skip_fact_type(fact_type)
	      next if fact_type.all_role.detect{|r| EntityType === r.concept }

	      @out.puts "/*\n * Fact Types\n */" unless done_banner
	      done_banner = true
	      fact_type_dump(fact_type)
#	    }
	}

      # REVISIT: Find out why some fact types are missed during entity dumping:
      @vocabulary.constellation.FactType.sort_by{|fact_type|
	  # Any sort key, as long as the result is stable. That means unique too!
	  [ (pr = preferred_reading(fact_type)).
	      role_sequence.
	      all_role_ref.
	      sort_by{|role_ref| role_ref.ordinal}.
	      map{|role_ref| [ role_ref.role.concept.name, role_ref.leading_adjective, role_ref.trailing_adjective ] },
	    pr.reading_text
	  ]
	}.each{|fact_type|
	  next if @fact_types_dumped[fact_type]
	  # puts "Not dumped #{fact_type.verbalise}(#{fact_type.all_role.map{|r| r.concept.name}*", "})"
	  @out.puts "/*\n * Fact Types\n */" unless done_banner
	  done_banner = true
	  fact_type_dump(fact_type)
	}

      @out.puts "\n" if done_banner
      # unused = constraints - @constraints_used.keys
      # $stderr.puts "residual constraints are\n\t#{unused.map(&:to_s)*",\n\t"}"

      @constraints_used
    end

    def fact_instances_dump
      @vocabulary.fact_types.each{|f|
	  # Dump the instances:
	  f.facts.each{|i|
	    @out.puts "\t\t"+i.to_s
	  }
      }
    end

    def constraints_dump(except = {})
      heading = false
      @vocabulary.all_constraint.sort_by{|c| c.name}.each{|c|
	  next if except[c]

	  # Skip some PresenceConstraints:
	  if PresenceConstraint === c
	    # Skip uniqueness constraints that cover all roles of a fact type, they're implicit
	    role_refs = c.role_sequence.all_role_ref
	    fact_type0 = role_refs[0].role.fact_type
	    next if c.max_frequency == 1 &&	    # Uniqueness
	      role_refs.size == fact_type0.all_role.size &&	# Same number of roles
	      fact_type0.all_role.all?{|r| role_refs.map(&:role).include? r}	# All present

	    # Skip internal PresenceConstraints over TypeInheritances:
	    next if TypeInheritance === fact_type0 &&
	      !c.role_sequence.all_role_ref.detect{|rr| rr.role.fact_type != fact_type0 }
	  end

	  unless heading
	    @out.puts "/*\nConstraints:"
	    heading = true
	  end

	  # Skip presence constraints on value types:
	  # next if ActiveFacts::PresenceConstraint === c &&
	  #     ActiveFacts::ValueType === c.concept
	  @out.puts "\tREVISIT: Verbalise #{c.class.basename} #{c.name}: " # +c.to_s
	}
      @out.puts " */" if heading
    end
  end

  def dump(vocabulary, out = $>)
    CQLDumper.new(vocabulary).dump(out)
    #out << vocabulary.constellation.verbalise + "\n"
  end
end

