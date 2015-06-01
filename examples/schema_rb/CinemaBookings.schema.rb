#
# schema.rb auto-generated using ActiveFacts for CinemaBookings on 2015-06-01
#

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Schema.define(:version => 20150601193610) do
  enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
  create_table "bookings", :id => false, :force => true do |t|
    t.column "booking_id", :primary_key, :null => false
    t.column "person_id", :integer, :null => false
    t.column "session_id", :integer, :null => false
    t.column "is_confirmed", :boolean, :null => true
    t.column "number", :integer, :limit => 16, :null => false
  end

  add_index "bookings", ["person_id", "session_id"], :name => :index_bookings_on_person_id_session_id, :unique => true

  create_table "cinemas", :id => false, :force => true do |t|
    t.column "cinema_id", :primary_key, :null => false
  end


  create_table "films", :id => false, :force => true do |t|
    t.column "film_id", :primary_key, :null => false
    t.column "name", :string, :null => true
  end


  create_table "people", :id => false, :force => true do |t|
    t.column "person_id", :primary_key, :null => false
    t.column "login_name", :string, :null => false
  end

  add_index "people", ["login_name"], :name => :index_people_on_login_name, :unique => true

  create_table "seats", :id => false, :force => true do |t|
    t.column "seat_id", :primary_key, :null => false
    t.column "row_cinema_id", :integer, :null => false
    t.column "row_nr", :string, :limit => 2, :null => false
    t.column "seat_number", :integer, :limit => 16, :null => false
    t.column "section_name", :string, :null => true
  end

  add_index "seats", ["row_cinema_id", "row_nr", "seat_number"], :name => :index_seats_on_row_cinema_id_row_nr_seat_number, :unique => true

  create_table "seat_allocations", :id => false, :force => true do |t|
    t.column "booking_id", :integer, :null => false
    t.column "allocated_seat_id", :integer, :null => false
  end

  add_index "seat_allocations", ["booking_id", "allocated_seat_id"], :name => :index_seat_allocations_on_booking_id_allocated_seat_id, :unique => true

  create_table "sessions", :id => false, :force => true do |t|
    t.column "session_id", :primary_key, :null => false
    t.column "cinema_id", :integer, :null => false
    t.column "film_id", :integer, :null => false
    t.column "date_time_value", :datetime, :null => false
  end

  add_index "sessions", ["cinema_id", "date_time_value"], :name => :index_sessions_on_cinema_id_date_time_value, :unique => true

  unless ENV["EXCLUDE_FKS"]
    add_foreign_key :bookings, :people, :column => :person_id, :primary_key => :person_id, :on_delete => :cascade
    add_index :bookings, [:person_id], :unique => false
    add_foreign_key :bookings, :sessions, :column => :session_id, :primary_key => :session_id, :on_delete => :cascade
    add_index :bookings, [:session_id], :unique => false
    add_foreign_key :seats, :cinemas, :column => :row_cinema_id, :primary_key => :cinema_id, :on_delete => :cascade
    add_index :seats, [:row_cinema_id], :unique => false
    add_foreign_key :seat_allocations, :bookings, :column => :booking_id, :primary_key => :booking_id, :on_delete => :cascade
    add_index :seat_allocations, [:booking_id], :unique => false
    add_foreign_key :seat_allocations, :seats, :column => :allocated_seat_id, :primary_key => :seat_id, :on_delete => :cascade
    add_index :seat_allocations, [:allocated_seat_id], :unique => false
    add_foreign_key :sessions, :cinemas, :column => :cinema_id, :primary_key => :cinema_id, :on_delete => :cascade
    add_index :sessions, [:cinema_id], :unique => false
    add_foreign_key :sessions, :films, :column => :film_id, :primary_key => :film_id, :on_delete => :cascade
    add_index :sessions, [:film_id], :unique => false
  end
end
