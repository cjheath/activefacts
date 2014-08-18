#
# schema.rb auto-generated using ActiveFacts for Astronomy on 2014-08-18
#

ActiveRecord::Schema.define(:version => 20140818141036) do
  create_table "astronomical_objects", :primary_key => :astronomical_object_id, :force => true do |t|
    t.string	"astronomical_object_code", :limit => 12, :null => false
    t.boolean	"is_in_orbit"
    t.Real	"mass", :limit => 32
    t.string	"moon_name", :limit => 256
    t.integer	"orbit_astronomical_object_id"
    t.Real	"orbit_nr_days", :limit => 32
    t.string	"planet_name", :limit => 256
  end

  add_index "astronomical_objects", ["astronomical_object_code"], :name => :index_astronomical_objects_on_astronomical_object_code, :unique => true

  unless ENV["EXCLUDE_FKS"]
    add_foreign_key :astronomical_objects, :astronomical_objects, :column => :orbit_astronomical_object_id, :primary_key => :astronomical_object_id, :dependent => :cascade
  end
end
