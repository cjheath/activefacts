#
# schema.rb auto-generated using ActiveFacts for CinemaBookings on 2013-06-23
#

ActiveRecord::Schema.define(:version => 20130623165949) do
  create_table "bookings", :primary_key => :booking_id, :force => true do |t|
    t.integer	"person_id", :null => false
    t.boolean	"is_confirmed"
    t.integer	"number", :null => false
    t.integer	"showing_cinema_id", :null => false
    t.datetime	"showing_date_time_value", :null => false
    t.integer	"showing_film_id", :null => false
  end

  add_index "bookings", ["person_id", "showing_cinema_id", "showing_film_id", "showing_date_time_value"], :name => :index_bookings_on_person_id_showing_cinema_id_showing__22f4afc6, :unique => true

  create_table "cinemas", :primary_key => :cinema_id, :force => true do |t|

  end


  create_table "films", :primary_key => :film_id, :force => true do |t|
    t.string	"name"
  end


  create_table "people", :primary_key => :person_id, :force => true do |t|
    t.string	"login_name", :null => false
  end

  add_index "people", ["login_name"], :name => :index_people_on_login_name, :unique => true

  create_table "seats", :primary_key => :seat_id, :force => true do |t|
    t.integer	"row_cinema_id", :null => false
    t.string	"row_nr", :limit => 2, :null => false
    t.integer	"seat_number", :null => false
    t.string	"section_name"
  end

  add_index "seats", ["row_cinema_id", "row_nr", "seat_number"], :name => :index_seats_on_row_cinema_id_row_nr_seat_number, :unique => true

  create_table "seat_allocations", :id => false, :force => true do |t|
    t.integer	"allocated_seat_id", :null => false
    t.integer	"booking_id", :null => false
  end

  add_index "seat_allocations", ["booking_id", "allocated_seat_id"], :name => :index_seat_allocations_on_booking_id_allocated_seat_id, :unique => true

  unless ENV["EXCLUDE_FKS"]
    add_foreign_key :bookings, :cinemas, :column => :showing_cinema_id, :primary_key => :cinema_id, :dependent => :cascade
    add_foreign_key :bookings, :films, :column => :showing_film_id, :primary_key => :film_id, :dependent => :cascade
    add_foreign_key :bookings, :people, :column => :person_id, :primary_key => :person_id, :dependent => :cascade
    add_foreign_key :seats, :cinemas, :column => :row_cinema_id, :primary_key => :cinema_id, :dependent => :cascade
    add_foreign_key :seat_allocations, :bookings, :column => :booking_id, :primary_key => :booking_id, :dependent => :cascade
    add_foreign_key :seat_allocations, :seats, :column => :allocated_seat_id, :primary_key => :seat_id, :dependent => :cascade
  end
end
