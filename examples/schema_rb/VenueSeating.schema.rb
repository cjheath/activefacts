#
# schema.rb auto-generated using ActiveFacts for VenueSeating on 2014-08-18
#

ActiveRecord::Schema.define(:version => 20140818120510) do
  create_table "events", :primary_key => :event_id, :force => true do |t|
    t.integer	"venue_id", :null => false
  end


  create_table "seats", :primary_key => :seat_id, :force => true do |t|
    t.integer	"venue_id", :null => false
    t.integer	"number", :null => false
    t.string	"reserve_name", :null => false
    t.string	"row_code", :null => false
  end

  add_index "seats", ["venue_id", "reserve_name", "row_code", "number"], :name => :index_seats_on_venue_id_reserve_name_row_code_number, :unique => true

  create_table "tickets", :id => false, :force => true do |t|
    t.integer	"event_id", :null => false
    t.integer	"seat_id", :null => false
  end

  add_index "tickets", ["event_id", "seat_id"], :name => :index_tickets_on_event_id_seat_id, :unique => true

  create_table "venues", :primary_key => :venue_id, :force => true do |t|

  end


  unless ENV["EXCLUDE_FKS"]
    add_foreign_key :events, :venues, :column => :venue_id, :primary_key => :venue_id, :dependent => :cascade
    add_foreign_key :seats, :venues, :column => :venue_id, :primary_key => :venue_id, :dependent => :cascade
    add_foreign_key :tickets, :events, :column => :event_id, :primary_key => :event_id, :dependent => :cascade
    add_foreign_key :tickets, :seats, :column => :seat_id, :primary_key => :seat_id, :dependent => :cascade
  end
end
