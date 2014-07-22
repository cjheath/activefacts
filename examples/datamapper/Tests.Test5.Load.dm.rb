require 'dm-core'
require 'dm-constraints'

class Birth
  include DataMapper::Resource

  property :attending_doctor_id, Integer	# maybe Birth was assisted by attending-Doctor and Party has Party Id
  belongs_to :attending_doctor, 'Doctor', :child_key => [:attending_doctor_id], :parent_key => [:party_id]	# attending_Doctor is involved in Birth
  property :event_date_ymd, DateTime, :key => true	# Birth is where Person was born on Event Date and Event Date has ymd
end

class Party
  include DataMapper::Resource

  property :party_id, Serial	# Party has Party Id
  property :party_moniker_accuracy_level, Integer, :required => true	# Party Moniker is where Party is called Party Name and Party Moniker has Accuracy and Accuracy has Accuracy Level
  property :party_moniker_party_name, String, :required => true	# Party Moniker is where Party is called Party Name and Party Moniker is where Party is called Party Name
end

class Person < Party
  property :death_event_date_ymd, DateTime	# Death is where Person died and maybe Death occurred on death-Event Date and Event Date has ymd
  property :died, Boolean	# Death is where Person died
end

class Doctor < Person
  has n, :birth_as_attending_doctor, 'Birth', :child_key => [:attending_doctor_id], :parent_key => [:party_id]	# Birth was assisted by attending-Doctor
end

