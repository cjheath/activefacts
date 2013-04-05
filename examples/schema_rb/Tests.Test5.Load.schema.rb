#
# schema.rb auto-generated using ActiveFacts for ORMModel1 on 2013-04-05
#

ActiveRecord::Schema.define(:version => 20130405112809) do
  create_table "parties", :primary_key => :party_id, :force => true do |t|
    t.integer	"party_moniker_accuracy_level", :null => false
    t.string	"party_moniker_party_name", :null => false
    t.integer	"person_attending_doctor_id"
    t.datetime	"person_death_event_date_ymd"
    t.boolean	"person_died"
    t.datetime	"person_event_date_ymd"
  end

  add_index "parties", ["person_attending_doctor_id", "person_event_date_ymd"], :name => :index_parties_on_person_attending_doctor_id_person_event_dat1

  unless ENV["EXCLUDE_FKS"]
    add_foreign_key :parties, :parties, :column => :person_attending_doctor_id, :primary_key => :party_id, :dependent => :cascade
  end
end
