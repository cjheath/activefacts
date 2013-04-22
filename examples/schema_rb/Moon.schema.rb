#
# schema.rb auto-generated using ActiveFacts for Moon on 2013-04-22
#

ActiveRecord::Schema.define(:version => 20130422144331) do
  create_table "moons", :primary_key => :moon_id, :force => true do |t|
    t.boolean	"is_in_orbit"
    t.string	"moon_name", :null => false
    t.integer	"orbit_nr_days_nr"
    t.string	"orbit_planet_name"
  end

  add_index "moons", ["moon_name"], :name => :index_moons_on_moon_name, :unique => true

  unless ENV["EXCLUDE_FKS"]

  end
end
