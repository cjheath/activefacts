$:.unshift File.dirname(File.expand_path(__FILE__))+"/../lib"

require 'rubygems'
require 'activefacts'
require 'activefacts/norma'
require "pp"

model = ActiveFacts::Norma.read(ARGV[0])

puts model.to_s

puts "All Object Types:"
model.object_types.each{|o|
	puts "\t"+o.to_s+" and plays roles in:"
	o.fact_types.each{|f|
		puts "\t\t"+f.to_s
	    }
    }

puts "All Fact Types:"
model.fact_types.each{|f|
	puts "\t"+f.to_s
	r = f.readings
#	puts r.to_yaml
	r.each{|r|
	    puts "\t\t"+r.to_s
	}
    }

puts "All Constraints:"
model.constraints.each{|c|
	# Skip presence constraints on value types:
    #    next if ActiveFacts::PresenceConstraint === c &&
    #	    ActiveFacts::ValueType === c.object_type
	puts "\t"+c.to_s
    }
