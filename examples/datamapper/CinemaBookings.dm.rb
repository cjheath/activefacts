require 'dm-core'
require 'dm-constraints'

class Booking
  include DataMapper::Resource

  property :is_confirmed, Boolean	# Booking is confirmed
  property :number, Integer, :key => true	# Booking is where Person booked Showing for Number of seats
  property :person_id, Integer, :key => true	# Booking is where Person booked Showing for Number of seats and Person has Person ID
  belongs_to :person	# Person is involved in Booking
  property :showing_cinema_id, Integer, :key => true	# Booking is where Person booked Showing for Number of seats and Showing is where Cinema shows Film on Date Time and Cinema has Cinema ID
  property :showing_date_time_value, DateTime, :key => true	# Booking is where Person booked Showing for Number of seats and Showing is where Cinema shows Film on Date Time and Date Time has Date Time Value
  property :showing_film_id, Integer, :key => true	# Booking is where Person booked Showing for Number of seats and Showing is where Cinema shows Film on Date Time and Film has Film ID
  has n, :seat_allocation, 'SeatAllocation', :child_key => [:booking_person_id, :booking_showing_cinema_id, :booking_showing_film_id, :booking_showing_date_time_value], :parent_key => [:person_id, :showing_cinema_id, :showing_film_id, :showing_date_time_value]	# Seat_Allocation is involved in Booking
end

class Cinema
  include DataMapper::Resource

  property :cinema_id, Serial	# Cinema has Cinema ID
end

class Film
  include DataMapper::Resource

  property :film_id, Serial	# Film has Film ID
  property :name, String	# maybe Film has Name
end

class Person
  include DataMapper::Resource

  property :login_name, String, :required => true	# Person has login-Name
  property :person_id, Serial	# Person has Person ID
  has n, :booking	# Person booked Showing for Number of seats
end

class Seat
  include DataMapper::Resource

  property :row_cinema_id, Integer, :key => true	# Seat is in Row and Row is in Cinema and Cinema has Cinema ID
  property :row_nr, String, :length => 2, :key => true	# Seat is in Row and Row has Row Nr
  property :seat_number, Integer, :key => true	# Seat has Seat Number
  property :section_name, String	# maybe Seat is in Section and Section has Section Name
  has n, :seat_allocation_as_allocated_seat, 'SeatAllocation', :child_key => [:allocated_seat_row_cinema_id, :allocated_seat_row_nr, :allocated_seat_number], :parent_key => [:row_cinema_id, :row_nr, :seat_number]	# Booking has allocated-Seat
end

class SeatAllocation
  include DataMapper::Resource

  property :booking_person_id, Integer, :key => true	# Seat Allocation is where Booking has allocated-Seat and Booking is where Person booked Showing for Number of seats and Person has Person ID
  property :booking_showing_cinema_id, Integer, :key => true	# Seat Allocation is where Booking has allocated-Seat and Booking is where Person booked Showing for Number of seats and Showing is where Cinema shows Film on Date Time and Cinema has Cinema ID
  property :booking_showing_date_time_value, DateTime, :key => true	# Seat Allocation is where Booking has allocated-Seat and Booking is where Person booked Showing for Number of seats and Showing is where Cinema shows Film on Date Time and Date Time has Date Time Value
  property :booking_showing_film_id, Integer, :key => true	# Seat Allocation is where Booking has allocated-Seat and Booking is where Person booked Showing for Number of seats and Showing is where Cinema shows Film on Date Time and Film has Film ID
  belongs_to :booking, :child_key => [:booking_person_id, :booking_showing_cinema_id, :booking_showing_film_id, :booking_showing_date_time_value], :parent_key => [:person_id, :showing_cinema_id, :showing_film_id, :showing_date_time_value]	# Booking is involved in Seat Allocation
  property :allocated_seat_number, Integer, :key => true	# Seat Allocation is where Booking has allocated-Seat and Seat has Seat Number
  property :allocated_seat_row_cinema_id, Integer, :key => true	# Seat Allocation is where Booking has allocated-Seat and Seat is in Row and Row is in Cinema and Cinema has Cinema ID
  property :allocated_seat_row_nr, String, :length => 2, :key => true	# Seat Allocation is where Booking has allocated-Seat and Seat is in Row and Row has Row Nr
  belongs_to :allocated_seat, 'Seat', :child_key => [:allocated_seat_row_cinema_id, :allocated_seat_row_nr, :allocated_seat_number], :parent_key => [:row_cinema_id, :row_nr, :seat_number]	# allocated_Seat is involved in Seat Allocation
end

