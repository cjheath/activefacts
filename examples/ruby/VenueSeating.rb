require 'activefacts/api'

module ::VenueSeating

  class EventId < AutoCounter
    value_type 
    one_to_one :event                           # See Event.event_id
  end

  class Number < UnsignedInteger
    value_type :length => 16
  end

  class ReserveName < String
    value_type 
    one_to_one :reserve                         # See Reserve.reserve_name
  end

  class RowCode < Char
    value_type 
    one_to_one :row                             # See Row.row_code
  end

  class VenueId < AutoCounter
    value_type 
    one_to_one :venue                           # See Venue.venue_id
  end

  class Event
    identified_by :event_id
    one_to_one :event_id, :mandatory => true    # See EventId.event
    has_one :venue, :mandatory => true          # See Venue.all_event
  end

  class Reserve
    identified_by :reserve_name
    one_to_one :reserve_name, :mandatory => true  # See ReserveName.reserve
  end

  class Row
    identified_by :row_code
    one_to_one :row_code, :mandatory => true    # See RowCode.row
  end

  class Venue
    identified_by :venue_id
    one_to_one :venue_id, :mandatory => true    # See VenueId.venue
  end

  class Seat
    identified_by :venue, :reserve, :row, :number
    has_one :number, :mandatory => true         # See Number.all_seat
    has_one :reserve, :mandatory => true        # See Reserve.all_seat
    has_one :row, :mandatory => true            # See Row.all_seat
    has_one :venue, :mandatory => true          # See Venue.all_seat
  end

  class Ticket
    identified_by :event, :seat
    has_one :event, :mandatory => true          # See Event.all_ticket
    has_one :seat, :mandatory => true           # See Seat.all_ticket
  end

end
