require 'dm-core'
require 'dm-constraints'

class Person
  include DataMapper::Resource

  property :death_cause_of_death, String	# Death is where Person is dead and maybe Death was due to Cause Of Death
  property :person_name, String, :length => 40, :key => true	# Person has Person Name
end

