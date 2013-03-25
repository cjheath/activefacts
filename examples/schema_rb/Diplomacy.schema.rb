#
# schema.rb auto-generated using ActiveFacts for Diplomacy on 2013-03-25
#

ActiveRecord::Schema.define(:version => 20130325151021) do
  create_table "countries", :primary_key => :country_id, :force => true do |t|
    t.string	"country_name", :null => false
  end

  add_index "countries", ["country_name"], :name => :index_countries_on_country_name, :unique => true

  create_table "diplomats", :primary_key => :diplomat_id, :force => true do |t|
    t.integer	"represented_country_id", :null => false
    t.integer	"served_country_id", :null => false
    t.string	"diplomat_name", :null => false
  end

  add_index "diplomats", ["diplomat_name"], :name => :index_diplomats_on_diplomat_name, :unique => true

  create_table "fluencies", :id => false, :force => true do |t|
    t.integer	"diplomat_id", :null => false
    t.integer	"language_id", :null => false
  end

  add_index "fluencies", ["diplomat_id", "language_id"], :name => :index_fluencies_on_diplomat_id_language_id, :unique => true

  create_table "languages", :primary_key => :language_id, :force => true do |t|
    t.string	"language_name", :null => false
  end

  add_index "languages", ["language_name"], :name => :index_languages_on_language_name, :unique => true

  create_table "language_uses", :id => false, :force => true do |t|
    t.integer	"country_id", :null => false
    t.integer	"language_id", :null => false
  end

  add_index "language_uses", ["language_id", "country_id"], :name => :index_language_uses_on_language_id_country_id, :unique => true

  create_table "representations", :id => false, :force => true do |t|
    t.integer	"ambassador_id", :null => false
    t.integer	"country_id", :null => false
    t.integer	"represented_country_id", :null => false
  end

  add_index "representations", ["represented_country_id", "country_id"], :name => :index_representations_on_represented_country_id_country_id, :unique => true

  unless ENV["EXCLUDE_FKS"]
    add_foreign_key :diplomats, :countries, :column => :represented_country_id, :primary_key => :country_id, :dependent => :cascade
    add_foreign_key :diplomats, :countries, :column => :served_country_id, :primary_key => :country_id, :dependent => :cascade
    add_foreign_key :fluencies, :diplomats, :column => :diplomat_id, :primary_key => :diplomat_id, :dependent => :cascade
    add_foreign_key :fluencies, :languages, :column => :language_id, :primary_key => :language_id, :dependent => :cascade
    add_foreign_key :language_uses, :countries, :column => :country_id, :primary_key => :country_id, :dependent => :cascade
    add_foreign_key :language_uses, :languages, :column => :language_id, :primary_key => :language_id, :dependent => :cascade
    add_foreign_key :representations, :countries, :column => :country_id, :primary_key => :country_id, :dependent => :cascade
    add_foreign_key :representations, :countries, :column => :represented_country_id, :primary_key => :country_id, :dependent => :cascade
    add_foreign_key :representations, :diplomats, :column => :ambassador_id, :primary_key => :diplomat_id, :dependent => :cascade
  end
end
