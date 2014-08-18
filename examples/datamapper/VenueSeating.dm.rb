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
  property :reserve_name, String, :key => true	# Seat is in Reserve and Reserve has Reserve Name
  property :row_code, String, :key => true	# Seat is in Row and Row has Row Code
  property :venue_id, Integer, :key => true	# Seat is at Venue and Venue has Venue Id
  belongs_to :venue	# Seat is at Venue
  has n, :ticket, :child_key => [:seat_venue_id, :seat_reserve_name, :seat_row_code, :seat_number], :parent_key => [:venue_id, :reserve_name, :row_code, :number]	# Ticket is for Seat
end

class Ticket
  include DataMapper::Resource

  property :event_id, Integer, :key => true	# Ticket is for Event and Event has Event Id
  belongs_to :event	# Ticket is for Event
  property :seat_number, Integer, :key => true	# Ticket is for Seat and Seat has Number
  property :seat_reserve_name, String, :key => true	# Ticket is for Seat and Seat is in Reserve and Reserve has Reserve Name
  property :seat_row_code, String, :key => true	# Ticket is for Seat and Seat is in Row and Row has Row Code
  property :seat_venue_id, Integer, :key => true	# Ticket is for Seat and Seat is at Venue and Venue has Venue Id
  belongs_to :seat, :child_key => [:seat_venue_id, :seat_reserve_name, :seat_row_code, :seat_number], :parent_key => [:venue_id, :reserve_name, :row_code, :number]	# Ticket is for Seat
end

class Venue
  include DataMapper::Resource

  property :venue_id, Serial	# Venue has Venue Id
  has n, :event	# Event is held at Venue
  has n, :seat	# Seat is at Venue
end

