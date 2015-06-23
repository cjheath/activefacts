#
# schema.rb auto-generated using ActiveFacts for Astronomy on 2015-06-01
#

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Schema.define(:version => 20150601204742) do
  enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
  create_table "astronomical_objects", :id => false, :force => true do |t|
    t.column "astronomical_object_id", :primary_key, :null => false
    t.column "astronomical_object_code", :string, :limit => 12, :null => false
    t.column "is_in_orbit", :boolean, :null => true
    t.column "mass", :float, :limit => 32, :null => true
    t.column "moon_name", :string, :limit => 256, :null => true
    t.column "orbit_center_astronomical_object_id", :integer, :null => true
    t.column "orbit_nr_days", :float, :limit => 32, :null => true
    t.column "planet_name", :string, :limit => 256, :null => true
  end

  add_index "astronomical_objects", ["astronomical_object_code"], :name => :index_astronomical_objects_on_astronomical_object_code, :unique => true

  unless ENV["EXCLUDE_FKS"]
    add_foreign_key :astronomical_objects, :astronomical_objects, :column => :orbit_center_astronomical_object_id, :primary_key => :astronomical_object_id, :on_delete => :cascade
    add_index :astronomical_objects, [:orbit_center_astronomical_object_id], :unique => false
  end
end
