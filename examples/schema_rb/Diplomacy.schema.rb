#
# schema.rb auto-generated using ActiveFacts for Diplomacy on 2015-07-08
#

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Schema.define(:version => 20150708011557) do
  enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
  create_table "countries", :id => false, :force => true do |t|
    t.column "country_id", :primary_key, :null => false
    t.column "country_name", :string, :null => false
  end

  add_index "countries", ["country_name"], :name => :index_countries_on_country_name, :unique => true

  create_table "diplomats", :id => false, :force => true do |t|
    t.column "diplomat_id", :primary_key, :null => false
    t.column "represented_country_id", :integer, :null => false
    t.column "served_country_id", :integer, :null => false
    t.column "diplomat_name", :string, :null => false
  end

  add_index "diplomats", ["diplomat_name"], :name => :index_diplomats_on_diplomat_name, :unique => true

  create_table "fluencies", :id => false, :force => true do |t|
    t.column "diplomat_id", :integer, :null => false
    t.column "language_id", :integer, :null => false
  end

  add_index "fluencies", ["diplomat_id", "language_id"], :name => :index_fluencies_on_diplomat_id_language_id, :unique => true

  create_table "languages", :id => false, :force => true do |t|
    t.column "language_id", :primary_key, :null => false
    t.column "language_name", :string, :null => false
  end

  add_index "languages", ["language_name"], :name => :index_languages_on_language_name, :unique => true

  create_table "language_uses", :id => false, :force => true do |t|
    t.column "language_id", :integer, :null => false
    t.column "country_id", :integer, :null => false
  end

  add_index "language_uses", ["language_id", "country_id"], :name => :index_language_uses_on_language_id_country_id, :unique => true

  create_table "representations", :id => false, :force => true do |t|
    t.column "representation_id", :primary_key, :null => false
    t.column "ambassador_id", :integer, :null => false
    t.column "country_id", :integer, :null => false
    t.column "represented_country_id", :integer, :null => false
  end

  add_index "representations", ["represented_country_id", "country_id"], :name => :index_representations_on_represented_country_id_country_id, :unique => true

  unless ENV["EXCLUDE_FKS"]
    add_foreign_key :diplomats, :countries, :column => :represented_country_id, :primary_key => :country_id, :on_delete => :cascade
    add_index :diplomats, [:represented_country_id], :unique => false, :name => :index_diplomats_on_represented_country_id
    add_foreign_key :diplomats, :countries, :column => :served_country_id, :primary_key => :country_id, :on_delete => :cascade
    add_index :diplomats, [:served_country_id], :unique => false, :name => :index_diplomats_on_served_country_id
    add_foreign_key :fluencies, :diplomats, :column => :diplomat_id, :primary_key => :diplomat_id, :on_delete => :cascade
    add_index :fluencies, [:diplomat_id], :unique => false, :name => :index_fluencies_on_diplomat_id
    add_foreign_key :fluencies, :languages, :column => :language_id, :primary_key => :language_id, :on_delete => :cascade
    add_index :fluencies, [:language_id], :unique => false, :name => :index_fluencies_on_language_id
    add_foreign_key :language_uses, :countries, :column => :country_id, :primary_key => :country_id, :on_delete => :cascade
    add_index :language_uses, [:country_id], :unique => false, :name => :index_language_uses_on_country_id
    add_foreign_key :language_uses, :languages, :column => :language_id, :primary_key => :language_id, :on_delete => :cascade
    add_index :language_uses, [:language_id], :unique => false, :name => :index_language_uses_on_language_id
    add_foreign_key :representations, :countries, :column => :country_id, :primary_key => :country_id, :on_delete => :cascade
    add_index :representations, [:country_id], :unique => false, :name => :index_representations_on_country_id
    add_foreign_key :representations, :countries, :column => :represented_country_id, :primary_key => :country_id, :on_delete => :cascade
    add_index :representations, [:represented_country_id], :unique => false, :name => :index_representations_on_represented_country_id
    add_foreign_key :representations, :diplomats, :column => :ambassador_id, :primary_key => :diplomat_id, :on_delete => :cascade
    add_index :representations, [:ambassador_id], :unique => false, :name => :index_representations_on_ambassador_id
  end
end
