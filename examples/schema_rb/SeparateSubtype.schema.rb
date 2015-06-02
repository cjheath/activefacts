#
# schema.rb auto-generated using ActiveFacts for SeparateSubtype on 2015-06-02
#

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Schema.define(:version => 20150602173457) do
  enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
  create_table "claims", :id => false, :force => true do |t|
    t.column "claim_id", :primary_key, :null => false
    t.column "incident_date_time", :datetime, :null => true
    t.column "incident_witness_id", :integer, :null => true
  end


  create_table "people", :id => false, :force => true do |t|
    t.column "person_id", :primary_key, :null => false
    t.column "person_name", :string, :null => false
  end

  add_index "people", ["person_name"], :name => :index_people_on_person_name, :unique => true

  create_table "vehicle_incidents", :id => false, :force => true do |t|
    t.column "incident_claim_id", :primary_key, :null => false
    t.column "driver_id", :integer, :null => true
  end


  unless ENV["EXCLUDE_FKS"]
    add_foreign_key :claims, :people, :column => :incident_witness_id, :primary_key => :person_id, :on_delete => :cascade
    add_index :claims, [:incident_witness_id], :unique => false
    add_foreign_key :vehicle_incidents, :claims, :column => :incident_claim_id, :primary_key => :claim_id, :on_delete => :cascade
    add_foreign_key :vehicle_incidents, :people, :column => :driver_id, :primary_key => :person_id, :on_delete => :cascade
    add_index :vehicle_incidents, [:driver_id], :unique => false
  end
end
