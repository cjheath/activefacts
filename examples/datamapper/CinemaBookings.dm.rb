require 'dm-core'
require 'dm-constraints'

class Booking
  include DataMapper::Resource

  property :count, Integer, :key => true	# Booking is where Person booked Showing for Count
  property :person_id, Integer, :key => true	# Booking is where Person booked Showing for Count and Person has PersonID
  belongs_to :person	# Person is involved in Booking
  property :showing_cinema_id, Integer, :key => true	# Booking is where Person booked Showing for Count and Showing is where Cinema shows Film on DateTime and Cinema has CinemaID
  property :showing_date_time_value, DateTime, :key => true	# Booking is where Person booked Showing for Count and Showing is where Cinema shows Film on DateTime and DateTime has DateTimeValue
  property :showing_film_id, Integer, :key => true	# Booking is where Person booked Showing for Count and Showing is where Cinema shows Film on DateTime and Film has FilmID
  has n, :seat_allocation, 'SeatAllocation', :child_key => [:booking_person_id, :booking_showing_cinema_id, :booking_showing_film_id, :booking_showing_date_time_value], :parent_key => [:person_id, :showing_cinema_id, :showing_film_id, :showing_date_time_value]	# Seat_Allocation is involved in Booking
end

class Cinema
  include DataMapper::Resource

  property :cinema_id, Serial	# Cinema has CinemaID
  has n, :seat	# Cinema has Seat
end

class Film
  include DataMapper::Resource

  property :film_id, Serial	# Film has FilmID
  property :name, String	# maybe Film has Name
end

class Person
  include DataMapper::Resource

  property :login_name, String, :required => true	# Person has login-Name
  property :person_id, Serial	# Person has PersonID
  has n, :booking	# Person booked Showing for Count
end

class Seat
  include DataMapper::Resource

  property :cinema_id, Integer, :key => true	# maybe Cinema has Seat and Cinema has CinemaID
  belongs_to :cinema	# Cinema has Seat
  property :number, Integer, :key => true	# Seat has Number
  property :row, String, :length => 2, :key => true	# Seat is in Row
  property :section_name, String	# maybe Seat is in Section and Section has SectionName
  has n, :seat_allocation_as_allocated_seat, 'SeatAllocation', :child_key => [:allocated_seat_cinema_id, :allocated_seat_row, :allocated_seat_number], :parent_key => [:cinema_id, :row, :number]	# Booking has allocated-Seat
end

class SeatAllocation
  include DataMapper::Resource

  property :booking_person_id, Integer, :key => true	# SeatAllocation is where Booking has allocated-Seat and Booking is where Person booked Showing for Count and Person has PersonID
  property :booking_showing_cinema_id, Integer, :key => true	# SeatAllocation is where Booking has allocated-Seat and Booking is where Person booked Showing for Count and Showing is where Cinema shows Film on DateTime and Cinema has CinemaID
  property :booking_showing_date_time_value, DateTime, :key => true	# SeatAllocation is where Booking has allocated-Seat and Booking is where Person booked Showing for Count and Showing is where Cinema shows Film on DateTime and DateTime has DateTimeValue
  property :booking_showing_film_id, Integer, :key => true	# SeatAllocation is where Booking has allocated-Seat and Booking is where Person booked Showing for Count and Showing is where Cinema shows Film on DateTime and Film has FilmID
  belongs_to :booking, :child_key => [:booking_person_id, :booking_showing_cinema_id, :booking_showing_film_id, :booking_showing_date_time_value], :parent_key => [:person_id, :showing_cinema_id, :showing_film_id, :showing_date_time_value]	# Booking is involved in SeatAllocation
  property :allocated_seat_cinema_id, Integer, :key => true	# SeatAllocation is where Booking has allocated-Seat and maybe Cinema has Seat and Cinema has CinemaID
  property :allocated_seat_number, Integer, :key => true	# SeatAllocation is where Booking has allocated-Seat and Seat has Number
  property :allocated_seat_row, String, :length => 2, :key => true	# SeatAllocation is where Booking has allocated-Seat and Seat is in Row
  belongs_to :allocated_seat, 'Seat', :child_key => [:allocated_seat_cinema_id, :allocated_seat_row, :allocated_seat_number], :parent_key => [:cinema_id, :row, :number]	# allocated_Seat is involved in SeatAllocation
end

