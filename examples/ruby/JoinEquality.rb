require 'activefacts/api'

module JoinEquality

  class EventId < AutoCounter
    value_type 
  end

  class Number < UnsignedSmallInteger
    value_type :length => 32
  end

  class Reserve < String
    value_type :length => 20
  end

  class Row < FixedLengthText
    value_type :length => 2
  end

  class VenueId < AutoCounter
    value_type 
  end

  class Event
    identified_by :event_id
    one_to_one :event_id                        # See EventId.event
    has_one :venue                              # See Venue.all_event
  end

  class Venue
    identified_by :venue_id
    one_to_one :venue_id                        # See VenueId.venue
  end

  class Seat
    identified_by :venue, :reserve, :row, :number
    has_one :number                             # See Number.all_seat
    has_one :reserve                            # See Reserve.all_seat
    has_one :row                                # See Row.all_seat
    has_one :venue                              # See Venue.all_seat
  end

  class Ticket
    identified_by :event, :seat
    has_one :event                              # See Event.all_ticket
    has_one :seat                               # See Seat.all_ticket
  end

end
