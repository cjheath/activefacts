$:.unshift File.dirname(File.expand_path(__FILE__))+"/../lib"

require 'rubygems'
require 'active_support'
require 'activefacts'
require 'activefacts/norma'
require "pp"
include ActiveFacts

model = ActiveFacts::Norma.read(ARGV[0])

puts model.to_s

def show_roles(o, f)
    num_fact_roles = f.roles.size
    o_fact_roles = f.roles.select{|r| r.object_type == o}
    nofr = o_fact_roles.size
    puts "\t\t#{f.name}" +
	(nofr > 1 ? ", #{o_fact_roles.size} of #{num_fact_roles} roles:" : "") +
	" (#{o_fact_roles.map(&:to_s)*", "})"
end

puts "All Entity Types:"
model.object_types.sort_by{|o| o.name}.each{|o|
	next if !(EntityType === o)	# includes NestedTypes
	puts "\t"+o.to_s+" and plays #{o.fact_types.size == 0 ? "no roles" : "roles in:"}"
	o.fact_types.each{|f| show_roles(o, f) }
    }

puts "\n\nAll Value Types:"
model.object_types.sort_by{|o| o.name}.each{|o|
	next if EntityType === o
	puts "\t"+o.to_s+" and plays #{o.fact_types.size == 0 ? "no roles" : "roles in:"}"
	o.fact_types.each{|f| show_roles(o, f) }
    }

puts "\n\nAll Fact Types:"
model.fact_types.each{|f|
	puts "\t"+f.to_s
	r = f.readings
#	puts r.to_yaml
	r.each{|r|
	    puts "\t\t"+r.to_s
	}
    }

puts "\n\nAll Constraints:"
model.constraints.each{|c|
	# Skip presence constraints on value types:
    #    next if ActiveFacts::PresenceConstraint === c &&
    #	    ActiveFacts::ValueType === c.object_type
	puts "\t"+c.to_s
    }
