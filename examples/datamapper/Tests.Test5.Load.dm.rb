require 'dm-core'

class Party
  include DataMapper::Resource

  property :party_id, Serial, :required => true, :key => true	# Party has Party Id
  property :party_moniker_accuracy_level, Integer, :required => true	# Party Moniker is where Party is called Party Name and Party Moniker has Accuracy and Accuracy has Accuracy Level
  property :party_moniker_party_name, String, :required => true	# Party Moniker is where Party is called Party Name and Party Moniker is where Party is called Party Name
end

class Person < Party
  property :birth_event_date_ymd, DateTime, :required => true	# Birth is where Person was born on Event Date and Birth is where Person was born on Event Date and Event Date has ymd
  property :birth_attending_doctor_id, Integer, :required => false	# Birth is where Person was born on Event Date and maybe Birth was assisted by attending-Doctor and Party has Party Id
  property :death_event_date_ymd, DateTime, :required => false	# Death is where Person died and maybe Death occurred on death-Event Date and Event Date has ymd
end

class Doctor < Person
end

