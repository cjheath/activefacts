#
# schema.rb auto-generated using ActiveFacts for Diplomacy on 2013-02-11
#

ActiveRecord::Schema.define(:version => 20130211114947) do
  create_table "countries", :id => false, :force => true do |t|
    t.string	"country_name", :null => false, :primary => true
  end

  add_index "countries", ["country_name"], :name => :index_countries_on_country_name, :unique => true

  create_table "diplomats", :id => false, :force => true do |t|
    t.string	"represented_country_name", :null => false
    t.string	"served_country_name", :null => false
    t.string	"diplomat_name", :null => false, :primary => true
  end

  add_index "diplomats", ["diplomat_name"], :name => :index_diplomats_on_diplomat_name, :unique => true

  create_table "fluencies", :id => false, :force => true do |t|
    t.string	"diplomat_name", :null => false
    t.string	"language_name", :null => false
  end

  add_index "fluencies", ["diplomat_name", "language_name"], :name => :index_fluencies_on_diplomat_name_language_name, :unique => true

  create_table "languages", :id => false, :force => true do |t|
    t.string	"language_name", :null => false, :primary => true
  end

  add_index "languages", ["language_name"], :name => :index_languages_on_language_name, :unique => true

  create_table "language_uses", :id => false, :force => true do |t|
    t.string	"country_name", :null => false
    t.string	"language_name", :null => false
  end

  add_index "language_uses", ["language_name", "country_name"], :name => :index_language_uses_on_language_name_country_name, :unique => true

  create_table "representations", :id => false, :force => true do |t|
    t.string	"ambassador_name", :null => false
    t.string	"country_name", :null => false
    t.string	"represented_country_name", :null => false
  end

  add_index "representations", ["represented_country_name", "country_name"], :name => :index_representations_on_represented_country_name_country_name, :unique => true

  add_foreign_key :diplomats, :countries, :column => :represented_country_name, :primary_key => :country_name, :dependent => :cascade
  add_foreign_key :diplomats, :countries, :column => :served_country_name, :primary_key => :country_name, :dependent => :cascade
  add_foreign_key :fluencies, :diplomats, :column => :diplomat_name, :primary_key => :diplomat_name, :dependent => :cascade
  add_foreign_key :fluencies, :languages, :column => :language_name, :primary_key => :language_name, :dependent => :cascade
  add_foreign_key :language_uses, :countries, :column => :country_name, :primary_key => :country_name, :dependent => :cascade
  add_foreign_key :language_uses, :languages, :column => :language_name, :primary_key => :language_name, :dependent => :cascade
  add_foreign_key :representations, :countries, :column => :country_name, :primary_key => :country_name, :dependent => :cascade
  add_foreign_key :representations, :countries, :column => :represented_country_name, :primary_key => :country_name, :dependent => :cascade
  add_foreign_key :representations, :diplomats, :column => :ambassador_name, :primary_key => :diplomat_name, :dependent => :cascade
end
