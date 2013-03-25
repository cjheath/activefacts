#
# schema.rb auto-generated using ActiveFacts for MonthInSeason on 2013-03-25
#

ActiveRecord::Schema.define(:version => 20130325151033) do
  create_table "months", :primary_key => :month_id, :force => true do |t|
    t.string	"month_value", :null => false
    t.string	"season"
  end

  add_index "months", ["month_value"], :name => :index_months_on_month_value, :unique => true

  create_table "occurrences", :primary_key => :occurrence_id, :force => true do |t|
    t.integer	"month_id", :null => false
    t.integer	"event_id", :null => false
  end

  add_index "occurrences", ["event_id", "month_id"], :name => :index_occurrences_on_event_id_month_id, :unique => true

  unless ENV["EXCLUDE_FKS"]
    add_foreign_key :occurrences, :months, :column => :month_id, :primary_key => :month_id, :dependent => :cascade
  end
end
