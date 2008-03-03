#
# Dump to API module for ActiveFacts models.
#
# Copyright (c) 2007 Clifford Heath. Read the LICENSE file.
# Author: Clifford Heath.
#
require 'activefacts/api'

module ActiveFacts

  class RubyGenerator
    def initialize(model)
      @model = model
    end

    def dump(out = $>)
      @out = out
      @out.puts "require 'activefacts/api'\n\n"
      @out.puts "module #{@model.name}\n\n"

      build_indices
      @concept_types_dumped = {}
      @fact_types_dumped = {}
      dump_value_types()
      dump_entity_types()
      dump_fact_types()

      @out.puts "end"
    end

    def build_indices
      @set_constraints_by_fact = Hash.new{ |h, k| h[k] = [] }
#      @ring_constraints_by_fact = Hash.new{ |h, k| h[k] = [] }

      @model.constraints.each { |c|
	  case c
	  when SetConstraint
	    fact_types = c.role_sequence.map(&:fact_type).uniq	# All fact types spanned by this constraint
	    if fact_types.size == 1	# There's only one, save it:
	      # $stderr.puts "Single-fact constraint on #{fact_types[0].name}: #{c.name}"
	      (@set_constraints_by_fact[fact_types[0]] ||= []) << c
	    end
#	  when RingConstraint
#	    (@ring_constraints_by_fact[c.from_role.fact_type] ||= []) << c
	  else
	    #puts "Found unhandled #{c.class} #{c.name}"
	  end
	}
      @constraints_used = {}
    end

    def dump_value_types
      @model.object_types.sort_by{|o| o.name}.each{|o|
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

      length = (l = o.data_type.length) && l > 0 ? ":length => #{l}" : nil
      scale = (s = o.data_type.scale) && s > 0 ? ":scale => #{s}" : nil
      params = [length,scale].compact * ", "

      ruby_type_name =
	case o.data_type.name
	  when "VariableLengthText"; "String"
	  when "Date"; "::Date"
	  else o.data_type.name
	end

      @out.puts "  class #{o.name} < #{ruby_type_name}\n" +
		"    value_type #{params}\n"
      dump_functional_roles(o)
      @out.puts "  end\n\n"
    end

    def ruby_role_name(role)
      role.role_name.snakecase.gsub("-",'_')
    end

    def known_by(roles)
      roles.map{|role|
	  ":"+ruby_role_name(role)
	}*", "
    end

    def show_role(r)
      puts "Role player #{r.object_type.name} facttype #{r.fact_type.name} lead_adj #{r.leading_adjective} trail_adj #{r.trailing_adjective} allows #{r.allowed_values.inspect}"
    end

    def dump_functional_roles(o)
      o.roles.each {|role|
	  dump_functional_role(role)
	}
    end

    def dump_binary(role_name, role_player, one_to_one = nil, readings = nil, other_role_name = nil)
      # Find whether we need the name of the other role player, and whether it's defined yet:
      if role_name.camelcase(true) == role_player
	# Don't use Class name if implied by rolename
	role_player = nil
      elsif !@concept_types_dumped[role_player]
	role_player = '"'+role_player.name+'"'
      else
	role_player = role_player.name
      end

      @out.puts "    binary " +
	      [ ":"+role_name,
		role_player,
		one_to_one,
		readings,
		other_role_name
	      ].compact*", "
    end

    def dump_functional_role(role)
      # REVISIT: Handle Unary Roles here
      return unless role.fact_type.roles.size == 2

      return if SubtypeFactType === role.fact_type

      # Find any uniqueness constraint over this role:
      fact_constraints = @set_constraints_by_fact[role.fact_type]
      ucs = fact_constraints.select{|c| PresenceConstraint === c && c.max == 1 }
      # Emit "binary..." only for functional roles here:
      return unless ucs.find {|c| c.role_sequence == [role] }

      other_role_number = role.fact_type.roles[0] == role ? 1 : 0
      other_role = role.fact_type.roles[other_role_number]
      other_role_name = ruby_role_name(other_role)
      other_player = other_role.object_type

      one_to_one = ucs.find {|c| c.role_sequence == [other_role] } ? "1" : nil
      
      # REVISIT: Add readings
      # REVISIT: Add other role name if defined

      dump_binary(other_role_name, other_player, one_to_one)
    end

    def dump_entity_type(o)
      pi = o.preferred_identifier

      if (supertype = o.primary_supertype)
	spi = o.primary_supertype.preferred_identifier
	# REVISIT: What about additional supertypes?
	@out.puts \
	      "  class #{o.name} < #{ o.supertypes[0].name }\n" +
	  (pi != spi ? "    entity_type #{known_by(pi.role_sequence)}\n" : "")
      else
	@out.puts \
	      "  class #{o.name}\n" +
	      "    entity_type #{known_by(pi.role_sequence)}"
      end
      dump_fact_roles(o.fact_type) if NestedType === o
      dump_functional_roles(o)
      @out.puts \
	      "  end\n\n"
      @constraints_used[pi] = true
    end

    # Try to dump entity types in order of name, but we need
    # to dump ETs before they're referenced in preferred ids
    # if possible (it's not always, there may be loops!)
    def dump_entity_types
      # Build hash tables of precursors and followers to use:
      entity_count = 0
      precursors, followers = *@model.object_types.inject([{},{}]) { |a, o|
	  if EntityType === o
	    entity_count += 1
	    precursor = a[0]
	    follower = a[1]
	    blocked = false
	    pi = o.preferred_identifier
	    if pi
	      pi.role_sequence.each{|r|
		  player = r.object_type
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

      sorted = @model.object_types.sort_by{|o| o.name}
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
		!f.roles.detect{|r| !@concept_types_dumped[r.object_type] }
	      }.each{|f|
		  dump_fact_type(f)
		}
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

    # Dump fact types.
    def dump_fact_types
      @model.fact_types.each{|f|
	  next if @fact_types_dumped[f] || skip_fact_type(f)

	  dump_fact_type(f)
	}
      @constraints_used
    end

    def skip_fact_type(f)
      # REVISIT: There might be constraints we have to merge into the nested entity or subtype. 
      # These will come up as un-handled constraints:
      f.nested_as ||
	SubtypeFactType === f
    end

    def dump_fact_roles(fact)
      fact.roles.each{|role| 
	  role_name = ruby_role_name(role)
	  dump_binary(role_name, role.object_type)
	}
    end

    # Dump one fact type.
    # Include as many as possible internal constraints in the fact type readings.
    def dump_fact_type(f)
      return if skip_fact_type(f)

      fact_constraints = @set_constraints_by_fact[f]

      # $stderr.puts "for fact type #{f.to_s}, considering\n\t#{fact_constraints.map(&:to_s)*",\n\t"}"
      # $stderr.puts "#{f.name} has readings:\n\t#{f.readings.map(&:name)*"\n\t"}"

      pc = fact_constraints.detect{|c|
	  PresenceConstraint === c &&
	  c.role_sequence.size > 1
	}
      return unless pc		# Omit fact types that aren't implicitly nested

      @out.puts "  class #{f.name}\t# Implicitly Objectified Fact Type\n" +
		"    entity_type #{known_by(pc.role_sequence)}"
      dump_fact_roles(f)
      @out.puts "  end\n\n"

      @fact_types_dumped[f] = true
    end
  end

  class Model
    def dump(out = $>)
      RubyGenerator.new(self).dump(out)
    end
  end
end

