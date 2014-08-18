require 'activefacts/api'

module ::CinemaTickets

  class AddressText < Text
    value_type 
  end

  class BookingNr < SignedInteger
    value_type :length => 32
  end

  class CinemaID < AutoCounter
    value_type 
  end

  class CollectionCode < SignedInteger
    value_type :length => 32
  end

  class Day < SignedInteger
    value_type :length => 32
    restrict 1..31
  end

  class EncryptedPassword < String
    value_type 
  end

  class FilmID < AutoCounter
    value_type 
  end

  class HighDemand < Boolean
    value_type 
  end

  class Hour < SignedInteger
    value_type :length => 32
    restrict 0..23
  end

  class Minute < SignedInteger
    value_type :length => 32
    restrict 0..59
  end

  class MonthNr < SignedInteger
    value_type :length => 32
    restrict 1..12
  end

  class Name < String
    value_type 
  end

  class Number < UnsignedInteger
    value_type :length => 16
    restrict 1..Infinity
  end

  class PaymentMethodCode < String
    value_type 
  end

  class PersonID < AutoCounter
    value_type 
  end

  class Price < Money
    value_type 
  end

  class RowNr < Char
    value_type :length => 2
  end

  class SeatNumber < UnsignedInteger
    value_type :length => 16
  end

  class SectionName < String
    value_type 
  end

  class YearNr < SignedInteger
    value_type :length => 32
    restrict 1900..9999
  end

  class Address
    identified_by :address_text
    one_to_one :address_text, :mandatory => true  # See AddressText.address
  end

  class Cinema
    identified_by :cinema_id
    one_to_one :cinema_id, :class => CinemaID, :mandatory => true  # See CinemaID.cinema
    one_to_one :name, :mandatory => true        # See Name.cinema
  end

  class Film
    identified_by :film_id
    one_to_one :film_id, :class => FilmID, :mandatory => true  # See FilmID.film
    has_one :name, :mandatory => true           # See Name.all_film
    has_one :year                               # See Year.all_film
  end

  class Month
    identified_by :month_nr
    one_to_one :month_nr, :mandatory => true    # See MonthNr.month
  end

  class PaymentMethod
    identified_by :payment_method_code
    one_to_one :payment_method_code, :mandatory => true  # See PaymentMethodCode.payment_method
  end

  class Person
    identified_by :person_id
    has_one :encrypted_password                 # See EncryptedPassword.all_person
    one_to_one :login_name, :class => Name      # See Name.person_as_login_name
    one_to_one :person_id, :class => PersonID, :mandatory => true  # See PersonID.person
  end

  class Row
    identified_by :cinema, :row_nr
    has_one :cinema, :mandatory => true         # See Cinema.all_row
    has_one :row_nr, :mandatory => true         # See RowNr.all_row
  end

  class Seat
    identified_by :row, :seat_number
    has_one :row, :mandatory => true            # See Row.all_seat
    has_one :seat_number, :mandatory => true    # See SeatNumber.all_seat
    has_one :section                            # See Section.all_seat
  end

  class Section
    identified_by :section_name
    one_to_one :section_name, :mandatory => true  # See SectionName.section
  end

  class Year
    identified_by :year_nr
    one_to_one :year_nr, :mandatory => true     # See YearNr.year
  end

  class AllocatableCinemaSection
    identified_by :cinema, :section
    has_one :cinema, :mandatory => true         # See Cinema.all_allocatable_cinema_section
    has_one :section, :mandatory => true        # See Section.all_allocatable_cinema_section
  end

  class SessionTime
    identified_by :year, :month, :day, :hour, :minute
    has_one :day, :mandatory => true            # See Day.all_session_time
    has_one :hour, :mandatory => true           # See Hour.all_session_time
    has_one :minute, :mandatory => true         # See Minute.all_session_time
    has_one :month, :mandatory => true          # See Month.all_session_time
    has_one :year, :mandatory => true           # See Year.all_session_time
  end

  class TicketPricing
    identified_by :session_time, :cinema, :section, :high_demand
    has_one :cinema, :mandatory => true         # See Cinema.all_ticket_pricing
    has_one :high_demand, :mandatory => true    # See HighDemand.all_ticket_pricing
    has_one :price, :mandatory => true          # See Price.all_ticket_pricing
    has_one :section, :mandatory => true        # See Section.all_ticket_pricing
    has_one :session_time, :mandatory => true   # See SessionTime.all_ticket_pricing
  end

  class Session
    identified_by :cinema, :session_time
    has_one :cinema, :mandatory => true         # See Cinema.all_session
    has_one :film, :mandatory => true           # See Film.all_session
    has_one :session_time, :mandatory => true   # See SessionTime.all_session
    maybe :is_high_demand
    maybe :uses_allocated_seating
  end

  class Booking
    identified_by :booking_nr
    has_one :number, :mandatory => true         # See Number.all_booking
    has_one :person, :mandatory => true         # See Person.all_booking
    has_one :session, :mandatory => true        # See Session.all_booking
    has_one :address                            # See Address.all_booking
    one_to_one :booking_nr, :mandatory => true  # See BookingNr.booking
    has_one :collection_code                    # See CollectionCode.all_booking
    has_one :section                            # See Section.all_booking
    maybe :tickets_forhave_been_issued
  end

  class PlacesPaid
    identified_by :booking, :payment_method
    has_one :booking, :mandatory => true        # See Booking.all_places_paid
    has_one :number, :mandatory => true         # See Number.all_places_paid
    has_one :payment_method, :mandatory => true  # See PaymentMethod.all_places_paid
  end

  class SeatAllocation
    identified_by :booking, :allocated_seat
    has_one :allocated_seat, :class => Seat, :mandatory => true  # See Seat.all_seat_allocation_as_allocated_seat
    has_one :booking, :mandatory => true        # See Booking.all_seat_allocation
  end

end
