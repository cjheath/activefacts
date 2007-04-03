#
# Simple test program that calls the ActiveFacts::Base API directly
#
$:.unshift File.dirname(File.expand_path(__FILE__))+"/../lib"

require 'rubygems'
require 'activefacts'
include ActiveFacts::Base

m = Model.new("foo")
puts m

d = DataType.new(m, "GivenName", "varchar", 20)
puts d

given = ValueType.new(m, "GivenName", d)
puts given

person = EntityType.new(m, "Person")
puts person

# One way to do it:
#f = FactType.new(m, "naming",
#	er = Role.new(m, person),
#	vr = Role.new(m, given)
#    )

# And the other:
f = FactType.new(m, "naming", person, given)

puts f

raise "shouldn't be #{m.object_types.size} object types in model" if m.object_types.size != 2
raise "shouldn't be #{m.fact_types.size} fact types in model" if m.fact_types.size != 1
raise "shouldn't be #{m.data_types.size} data types in model" if m.data_types.size != 1

