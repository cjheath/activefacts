#
# schema.rb auto-generated using ActiveFacts for VenueSeating on 2015-07-08
#

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Schema.define(:version => 20150708011603) do
  enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
  create_table "events", :id => false, :force => true do |t|
    t.column "event_id", :primary_key, :null => false
    t.column "venue_id", :integer, :null => false
  end


  create_table "seats", :id => false, :force => true do |t|
    t.column "seat_id", :primary_key, :null => false
    t.column "venue_id", :integer, :null => false
    t.column "number", :integer, :limit => 16, :null => false
    t.column "reserve_name", :string, :null => false
    t.column "row_code", :string, :null => false
  end

  add_index "seats", ["venue_id", "reserve_name", "row_code", "number"], :name => :index_seats_on_venue_id_reserve_name_row_code_number, :unique => true

  create_table "tickets", :id => false, :force => true do |t|
    t.column "event_id", :integer, :null => false
    t.column "seat_id", :integer, :null => false
  end

  add_index "tickets", ["event_id", "seat_id"], :name => :index_tickets_on_event_id_seat_id, :unique => true

  create_table "venues", :id => false, :force => true do |t|
    t.column "venue_id", :primary_key, :null => false
  end


  unless ENV["EXCLUDE_FKS"]
    add_foreign_key :events, :venues, :column => :venue_id, :primary_key => :venue_id, :on_delete => :cascade
    add_index :events, [:venue_id], :unique => false, :name => :index_events_on_venue_id
    add_foreign_key :seats, :venues, :column => :venue_id, :primary_key => :venue_id, :on_delete => :cascade
    add_index :seats, [:venue_id], :unique => false, :name => :index_seats_on_venue_id
    add_foreign_key :tickets, :events, :column => :event_id, :primary_key => :event_id, :on_delete => :cascade
    add_index :tickets, [:event_id], :unique => false, :name => :index_tickets_on_event_id
    add_foreign_key :tickets, :seats, :column => :seat_id, :primary_key => :seat_id, :on_delete => :cascade
    add_index :tickets, [:seat_id], :unique => false, :name => :index_tickets_on_seat_id
  end
end
