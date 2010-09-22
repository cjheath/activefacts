require 'dm-core'

class Person
  include DataMapper::Resource

  property :person_name, String, :length => 40, :required => true, :key => true	# Person has Person Name
  property :death_cause_of_death, String, :required => false	# Death is where Person is dead and maybe Death was due to Cause Of Death
end

