require 'dm-core'

class Month
  include DataMapper::Resource

  property :season, String, :required => false	# maybe Month is in Season
  property :month_value, String, :required => true, :key => true	# Month has value
  has n, :occurrence	# Event occurred in Month
end

class Occurrence
  include DataMapper::Resource

  property :event_id, Integer, :required => true, :key => true	# Occurrence is where Event occurred in Month and Event has Event Id
  property :month_value, String, :required => true, :key => true	# Occurrence is where Event occurred in Month and Month has value
  belongs_to :month	# Month is involved in Occurrence
end

