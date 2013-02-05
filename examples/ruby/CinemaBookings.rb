require 'activefacts/api'

module ::CinemaBookings

  class CinemaID < AutoCounter
    value_type 
  end

  class Count < UnsignedInteger
    value_type :length => 16
    restrict 1..Infinity
  end

  class DateTimeValue < DateTime
    value_type 
  end

  class FilmID < AutoCounter
    value_type 
  end

  class Name < String
    value_type 
  end

  class Number < UnsignedInteger
    value_type :length => 16
  end

  class PersonID < AutoCounter
    value_type 
  end

  class Row < Char
    value_type :length => 2
  end

  class SectionName < String
    value_type 
  end

  class Cinema
    identified_by :cinema_id
    one_to_one :cinema_id, :class => CinemaID, :mandatory => true  # See CinemaID.cinema
  end

  class DateTime
    identified_by :date_time_value
    one_to_one :date_time_value, :mandatory => true  # See DateTimeValue.date_time
  end

  class Film
    identified_by :film_id
    one_to_one :film_id, :class => FilmID, :mandatory => true  # See FilmID.film
    has_one :name                               # See Name.all_film
  end

  class Person
    identified_by :person_id
    has_one :login_name, :class => Name, :mandatory => true  # See Name.all_person_as_login_name
    one_to_one :person_id, :class => PersonID, :mandatory => true  # See PersonID.person
  end

  class Seat
    identified_by :cinema, :row, :number
    has_one :cinema                             # See Cinema.all_seat
    has_one :number, :mandatory => true         # See Number.all_seat
    has_one :row, :mandatory => true            # See Row.all_seat
    has_one :section                            # See Section.all_seat
  end

  class Section
    identified_by :section_name
    one_to_one :section_name, :mandatory => true  # See SectionName.section
  end

  class Showing
    identified_by :cinema, :film, :date_time
    has_one :cinema, :mandatory => true         # See Cinema.all_showing
    has_one :date_time, :mandatory => true      # See DateTime.all_showing
    has_one :film, :mandatory => true           # See Film.all_showing
  end

  class Booking
    identified_by :person, :showing
    has_one :count, :mandatory => true          # See Count.all_booking
    has_one :person, :mandatory => true         # See Person.all_booking
    has_one :showing, :mandatory => true        # See Showing.all_booking
  end

  class SeatAllocation
    identified_by :booking, :allocated_seat
    has_one :allocated_seat, :class => Seat, :mandatory => true  # See Seat.all_seat_allocation_as_allocated_seat
    has_one :booking, :mandatory => true        # See Booking.all_seat_allocation
  end

end
