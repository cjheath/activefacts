#
# schema.rb auto-generated using ActiveFacts for CinemaBookings on 2013-02-11
#

ActiveRecord::Schema.define(:version => 20130211162841) do
  create_table "bookings", :id => false, :force => true do |t|
    t.integer	"person_id", :null => false
    t.integer	"count", :null => false
    t.integer	"showing_cinema_id", :null => false
    t.datetime	"showing_date_time_value", :null => false
    t.integer	"showing_film_id", :null => false
  end

  add_index "bookings", ["person_id", "showing_cinema_id", "showing_film_id", "showing_date_time_value"], :name => :index_bookings_on_person_id_showing_cinema_id_showing_film_i1, :unique => true

  create_table "cinemas", :primary_key => :cinema_id, :force => true do |t|

  end

  add_index "cinemas", ["cinema_id"], :name => :index_cinemas_on_cinema_id, :unique => true

  create_table "films", :primary_key => :film_id, :force => true do |t|
    t.string	"name"
  end

  add_index "films", ["film_id"], :name => :index_films_on_film_id, :unique => true

  create_table "people", :primary_key => :person_id, :force => true do |t|
    t.string	"login_name", :null => false
  end

  add_index "people", ["person_id"], :name => :index_people_on_person_id, :unique => true

  create_table "seats", :id => false, :force => true do |t|
    t.integer	"cinema_id"
    t.integer	"number", :null => false
    t.string	"row", :limit => 2, :null => false
    t.string	"section_name"
  end

  add_index "seats", ["cinema_id", "row", "number"], :name => :index_seats_on_cinema_id_row_number

  create_table "seat_allocations", :id => false, :force => true do |t|
    t.integer	"allocated_seat_cinema_id"
    t.integer	"allocated_seat_number", :null => false
    t.string	"allocated_seat_row", :limit => 2, :null => false
    t.integer	"booking_person_id", :null => false
    t.integer	"booking_showing_cinema_id", :null => false
    t.datetime	"booking_showing_date_time_value", :null => false
    t.integer	"booking_showing_film_id", :null => false
  end

  add_index "seat_allocations", ["booking_person_id", "booking_showing_cinema_id", "booking_showing_film_id", "booking_showing_date_time_value", "allocated_seat_cinema_id", "allocated_seat_row", "allocated_seat_number"], :name => :index_seat_allocations_on_booking_person_id_booking_showing_2

  add_foreign_key :bookings, :people, :column => :person_id, :primary_key => :person_id, :dependent => :cascade
  add_foreign_key :seats, :cinemas, :column => :cinema_id, :primary_key => :cinema_id, :dependent => :cascade
  add_foreign_key :bookings, :seat_allocations, :column => [:booking_person_id:, booking_showing_cinema_id:, booking_showing_date_time_value:, booking_showing_film_id], :primary_key => [:person_id:, showing_cinema_id:, showing_date_time_value:, showing_film_id], :dependent => :cascade
  add_foreign_key :seats, :seat_allocations, :column => [:allocated_seat_cinema_id:, allocated_seat_number:, allocated_seat_row], :primary_key => [:cinema_id:, number:, row], :dependent => :cascade
end
