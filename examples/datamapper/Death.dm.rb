require 'dm-core'

class Person
  include DataMapper::Resource

  property :person_name, String, :length => 40, :key => true	# Person has Person Name
  property :death_cause_of_death, String	# Death is where Person is dead and maybe Death was due to Cause Of Death
end

