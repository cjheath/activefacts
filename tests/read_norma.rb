$:.unshift File.dirname(File.expand_path(__FILE__))+"/../lib"

require 'rubygems'
require 'activefacts'
require 'activefacts/norma'
require "pp"

model = ActiveFacts::Norma.read(ARGV[0])

puts model.to_s
model.object_types.each{|o|
    puts "\t"+o.to_s
    o.fact_types.each{|f|
	puts "\t\t"+f.to_s
	f.readings.each{|r|
	    puts "\t\t\t"+r.to_s
	}
    }
}

puts model.constraints.map{|c| c.to_s}
