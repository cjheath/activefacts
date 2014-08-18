#
# schema.rb auto-generated using ActiveFacts for CinemaTickets on 2014-08-18
#

ActiveRecord::Schema.define(:version => 20140818131824) do
  create_table "allocatable_cinema_sections", :primary_key => :allocatable_cinema_section_id, :force => true do |t|
    t.integer	"cinema_id", :null => false
    t.string	"section_name", :null => false
  end

  add_index "allocatable_cinema_sections", ["cinema_id", "section_name"], :name => :index_allocatable_cinema_sections_on_cinema_id_section_name, :unique => true

  create_table "bookings", :primary_key => :booking_id, :force => true do |t|
    t.integer	"person_id", :null => false
    t.integer	"session_id", :null => false
    t.text	"address_text"
    t.integer	"booking_nr", :null => false
    t.integer	"collection_code"
    t.integer	"number", :null => false
    t.string	"section_name"
    t.boolean	"tickets_for_have_been_issued"
  end

  add_index "bookings", ["booking_nr"], :name => :index_bookings_on_booking_nr, :unique => true
  add_index "bookings", ["person_id", "session_id"], :name => :index_bookings_on_person_id_session_id, :unique => true

  create_table "cinemas", :primary_key => :cinema_id, :force => true do |t|
    t.string	"name", :null => false
  end

  add_index "cinemas", ["name"], :name => :index_cinemas_on_name, :unique => true

  create_table "films", :primary_key => :film_id, :force => true do |t|
    t.string	"name", :null => false
    t.integer	"year_nr"
  end

  add_index "films", ["name", "year_nr"], :name => :index_films_on_name_year_nr

  create_table "people", :primary_key => :person_id, :force => true do |t|
    t.string	"encrypted_password"
    t.string	"login_name"
  end

  add_index "people", ["login_name"], :name => :index_people_on_login_name

  create_table "places_paids", :primary_key => :places_paid_id, :force => true do |t|
    t.integer	"booking_id", :null => false
    t.integer	"number", :null => false
    t.string	"payment_method_code", :null => false
  end

  add_index "places_paids", ["booking_id", "payment_method_code"], :name => :index_places_paids_on_booking_id_payment_method_code, :unique => true

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

  create_table "sessions", :primary_key => :session_id, :force => true do |t|
    t.integer	"cinema_id", :null => false
    t.integer	"film_id", :null => false
    t.boolean	"is_high_demand"
    t.integer	"session_time_day", :null => false
    t.integer	"session_time_hour", :null => false
    t.integer	"session_time_minute", :null => false
    t.integer	"session_time_month_nr", :null => false
    t.integer	"session_time_year_nr", :null => false
    t.boolean	"uses_allocated_seating"
  end

  add_index "sessions", ["cinema_id", "session_time_year_nr", "session_time_month_nr", "session_time_day", "session_time_hour", "session_time_minute"], :name => :index_sessions_on_cinema_id_session_time_year_nr_sess__7a05f3be, :unique => true

  create_table "ticket_pricings", :primary_key => :ticket_pricing_id, :force => true do |t|
    t.integer	"cinema_id", :null => false
    t.Boolean	"high_demand", :null => false
    t.decimal	"price", :null => false
    t.string	"section_name", :null => false
    t.integer	"session_time_day", :null => false
    t.integer	"session_time_hour", :null => false
    t.integer	"session_time_minute", :null => false
    t.integer	"session_time_month_nr", :null => false
    t.integer	"session_time_year_nr", :null => false
  end

  add_index "ticket_pricings", ["session_time_year_nr", "session_time_month_nr", "session_time_day", "session_time_hour", "session_time_minute", "cinema_id", "section_name", "high_demand"], :name => :index_ticket_pricings_on_session_time_year_nr_session__181a38a0, :unique => true

  unless ENV["EXCLUDE_FKS"]
    add_foreign_key :allocatable_cinema_sections, :cinemas, :column => :cinema_id, :primary_key => :cinema_id, :dependent => :cascade
    add_foreign_key :bookings, :people, :column => :person_id, :primary_key => :person_id, :dependent => :cascade
    add_foreign_key :bookings, :sessions, :column => :session_id, :primary_key => :session_id, :dependent => :cascade
    add_foreign_key :places_paids, :bookings, :column => :booking_id, :primary_key => :booking_id, :dependent => :cascade
    add_foreign_key :seats, :cinemas, :column => :row_cinema_id, :primary_key => :cinema_id, :dependent => :cascade
    add_foreign_key :seat_allocations, :bookings, :column => :booking_id, :primary_key => :booking_id, :dependent => :cascade
    add_foreign_key :seat_allocations, :seats, :column => :allocated_seat_id, :primary_key => :seat_id, :dependent => :cascade
    add_foreign_key :sessions, :cinemas, :column => :cinema_id, :primary_key => :cinema_id, :dependent => :cascade
    add_foreign_key :sessions, :films, :column => :film_id, :primary_key => :film_id, :dependent => :cascade
    add_foreign_key :ticket_pricings, :cinemas, :column => :cinema_id, :primary_key => :cinema_id, :dependent => :cascade
  end
end
