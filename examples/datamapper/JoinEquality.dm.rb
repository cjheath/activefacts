require 'dm-core'
require 'dm-constraints'

class Event
  include DataMapper::Resource

  property :event_id, Serial	# Event has Event Id
  property :venue_id, Integer, :required => true	# Event is held at Venue and Venue has Venue Id
  belongs_to :venue	# Event is held at Venue
  has n, :ticket	# Ticket is for Event
end

class Seat
  include DataMapper::Resource

  property :number, Integer, :key => true	# Seat has Number
  property :reserve, String, :length => 20, :key => true	# Seat is in Reserve
  property :row, String, :length => 2, :key => true	# Seat is in Row
  property :venue_id, Integer, :key => true	# Seat is at Venue and Venue has Venue Id
  belongs_to :venue	# Seat is at Venue
  has n, :ticket, :child_key => [:seat_number, :seat_reserve, :seat_row, :seat_venue_id], :parent_key => [:number, :reserve, :row, :venue_id]	# Ticket is for Seat
end

class Ticket
  include DataMapper::Resource

  property :event_id, Integer, :key => true	# Ticket is for Event and Event has Event Id
  belongs_to :event	# Ticket is for Event
  property :seat_number, Integer, :key => true	# Ticket is for Seat and Seat has Number
  property :seat_reserve, String, :length => 20, :key => true	# Ticket is for Seat and Seat is in Reserve
  property :seat_row, String, :length => 2, :key => true	# Ticket is for Seat and Seat is in Row
  property :seat_venue_id, Integer, :key => true	# Ticket is for Seat and Seat is at Venue and Venue has Venue Id
  belongs_to :seat, :child_key => [:seat_number, :seat_reserve, :seat_row, :seat_venue_id], :parent_key => [:number, :reserve, :row, :venue_id]	# Ticket is for Seat
end

class Venue
  include DataMapper::Resource

  property :venue_id, Serial	# Venue has Venue Id
  has n, :event	# Event is held at Venue
  has n, :seat	# Seat is at Venue
end

