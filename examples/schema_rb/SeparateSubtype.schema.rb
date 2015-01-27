#
# schema.rb auto-generated using ActiveFacts for SeparateSubtype on 2015-01-27
#

ActiveRecord::Schema.define(:version => 20150127152048) do
  create_table "claims", :primary_key => :claim_id, :force => true do |t|
    t.datetime	"incident_date_time"
    t.integer	"incident_witness_id"
  end


  create_table "people", :primary_key => :person_id, :force => true do |t|
    t.string	"person_name", :null => false
  end

  add_index "people", ["person_name"], :name => :index_people_on_person_name, :unique => true

  create_table "vehicle_incidents", :primary_key => :incident_claim_id, :force => true do |t|
    t.integer	"driver_id"
  end


  unless ENV["EXCLUDE_FKS"]
    add_foreign_key :claims, :people, :column => :incident_witness_id, :primary_key => :person_id, :dependent => :cascade
    add_foreign_key :vehicle_incidents, :claims, :column => :incident_claim_id, :primary_key => :claim_id, :dependent => :cascade
    add_foreign_key :vehicle_incidents, :people, :column => :driver_id, :primary_key => :person_id, :dependent => :cascade
  end
end
