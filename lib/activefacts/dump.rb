#
# Dump module for ActiveFacts models.
#
# Adds the Model.dump() method.
#
# Copyright (c) 2007 Clifford Heath. Read the LICENSE file.
# Author: Clifford Heath.
#
module ActiveFacts

    module Dump
	def self.show_roles(out, o, f)
	    pi = EntityType === o && o.preferred_identifier

	    out.puts "\t\t#{f.name}(#{f.roles.map{|r|
		    r.to_s
		}*", "})" + (
			pi && pi.role_sequence.detect{|r|
			    f.roles.include?(r)
			} ? " #" : ""
		    )
	    return

	    num_fact_roles = f.roles.size
	    o_fact_roles = f.roles.select{|r| r.object_type == o}
	    nofr = o_fact_roles.size
	    out.puts "\t\t#{f.name}" +
		(nofr == 1 ? "" : ", #{o_fact_roles.size} of #{num_fact_roles} roles:") +
		" (#{o_fact_roles.map(&:to_s)*", "})"
	end
    end

    class Model
	def dump_entity_types(out = $>)
	    out.puts "All Entity Types:"
	    object_types.sort_by{|o| o.name}.each{|o|
		    next if !(EntityType === o)	# includes NestedTypes
		    out.puts "\t"+o.to_s+" and plays #{o.fact_types.size == 0 ? "no roles" : "roles in:"}"
		    o.fact_types.each{|f| Dump.show_roles(out, o, f) }
		}
	end

	def dump_value_types(out = $>)
	    out.puts "\n\nAll Value Types:"
	    object_types.sort_by{|o| o.name}.each{|o|
		    next if EntityType === o
		    out.puts "\t"+o.to_s+
			" and plays #{o.fact_types.size == 0 ? "no roles" : "roles in:"}"
		    o.fact_types.each{|f| Dump.show_roles(out, o, f) }
		}
	end

	def dump_fact_types(out = $>)
	    out.puts "\n\nAll Fact Types:"
	    fact_types.each{|f|
		    out.puts "\t"+f.to_s

		    # Dump the readings:
		    r = f.readings
		#   out.puts r.to_yaml
		    r.each{|r|
			out.puts "\t\t"+r.to_s
		    }

		    # Dump the instances:
		    f.facts.each{|i|
			out.puts "\t\t"+i.to_s
		    }
		}
	end

	def dump_constraint_types(out = $>)
	    out.puts "\n\nAll Constraints:"
	    constraints.each{|c|
		    # Skip presence constraints on value types:
		#   next if ActiveFacts::PresenceConstraint === c &&
		#	    ActiveFacts::ValueType === c.object_type
		    out.puts "\t"+c.to_s
		}
	end

	def dump(out = $>)
	    out.puts to_s

	    dump_entity_types(out)
	    dump_value_types(out)
	    dump_fact_types(out)
	    dump_constraint_types(out)
	end
    end
end

