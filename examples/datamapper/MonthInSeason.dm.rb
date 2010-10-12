require 'dm-core'
require 'dm-constraints'

class Month
  include DataMapper::Resource

  property :season, String	# maybe Month is in Season
  property :month_value, String, :key => true	# Month has value
  has n, :occurrence	# Event occurred in Month
end

class Occurrence
  include DataMapper::Resource

  property :event_id, Integer, :key => true	# Occurrence is where Event occurred in Month and Event has Event Id
  property :month_value, String, :key => true	# Occurrence is where Event occurred in Month and Month has value
  belongs_to :month	# Month is involved in Occurrence
end

