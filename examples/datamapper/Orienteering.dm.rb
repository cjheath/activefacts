require 'dm-core'
require 'dm-constraints'

class Club
  include DataMapper::Resource

  property :club_code, String, :length => 6, :key => true	# Club has Club Code
  property :club_name, String, :length => 32, :required => true	# Club Name is name of Club
  has n, :event	# Club runs Event
  has n, :map_as_owner, 'Map', :child_key => [:owner_code], :parent_key => [:club_code]	# Club owns Map
  has n, :person	# Person is member of Club
end

class Entry
  include DataMapper::Resource

  property :course, String, :length => 16, :key => true	# Entry is where Person entered Course of Event
  property :entry_id, Serial	# Entry has Entry ID
  property :event_id, Serial	# Entry is where Person entered Course of Event and Event has Event ID
  belongs_to :event	# Event is involved in Entry
  property :person_id, Serial	# Entry is where Person entered Course of Event and Person has Person ID
  belongs_to :person	# Person is involved in Entry
  property :finish_placing, Integer	# maybe Entry finished in finish-Placing
  property :score, Integer	# maybe Entry received Score
  has n, :visit	# Visit is involved in Entry
end

class Event
  include DataMapper::Resource

  property :club_code, String, :length => 6, :required => true	# Club runs Event and Club has Club Code
  belongs_to :club	# Club runs Event
  property :event_id, Serial	# Event has Event ID
  property :event_name, String, :length => 50	# maybe Event is called Event Name
  property :start_location, String, :length => 200, :required => true	# Event starts at start-Location
  property :map_id, Integer, :required => true	# Map is map for Event and Map has Map ID
  belongs_to :map	# Map is map for Event
  property :number, Integer	# maybe Event has Number
  property :series_id, Integer	# maybe Event is in Series and Series has Series ID
  belongs_to :series	# Event is in Series
  property :start_time, DateTime, :required => true	# Event is held on Start Time
  has n, :entry	# Person entered Course of Event
  has n, :event_control, 'EventControl'	# Event includes Control Number
  has n, :event_scoring_method, 'EventScoringMethod'	# Scoring Method is used for Course of Event
end

class EventControl
  include DataMapper::Resource

  property :control_number, Integer, :key => true	# Event Control is where Event includes Control Number
  property :event_id, Integer, :key => true	# Event Control is where Event includes Control Number and Event has Event ID
  belongs_to :event	# Event is involved in Event Control
  property :point_value, Integer	# maybe Event Control has Point Value
  has n, :punch_placement, 'PunchPlacement', :child_key => [:event_control_number, :event_control_event_id], :parent_key => [:control_number, :event_id]	# Punch_Placement is involved in Event Control
end

class EventScoringMethod
  include DataMapper::Resource

  property :course, String, :length => 16, :key => true	# Event Scoring Method is where Scoring Method is used for Course of Event
  property :event_id, Integer, :key => true	# Event Scoring Method is where Scoring Method is used for Course of Event and Event has Event ID
  belongs_to :event	# Event is involved in Event Scoring Method
  property :scoring_method, String, :length => 32, :key => true	# Event Scoring Method is where Scoring Method is used for Course of Event
end

class Map
  include DataMapper::Resource

  property :accessibility, String, :length => 1	# maybe Map has Accessibility
  property :owner_code, String, :length => 6, :required => true	# Club owns Map and Club has Club Code
  belongs_to :owner, 'Club', :child_key => [:owner_code], :parent_key => [:club_code]	# Club owns Map
  property :map_id, Serial	# Map has Map ID
  property :map_name, String, :length => 80, :required => true	# Map has Map Name
  has n, :event	# Map is map for Event
end

class Person
  include DataMapper::Resource

  property :club_code, String, :length => 6	# maybe Person is member of Club and Club has Club Code
  belongs_to :club	# Person is member of Club
  property :family_name, String, :length => 48, :required => true	# Person has Family Name
  property :gender, String, :length => 1	# maybe Person is of Gender
  property :given_name, String, :length => 48, :required => true	# Person has Given Name
  property :person_id, Serial	# Person has Person ID
  property :post_code, Integer	# maybe Person has Post Code
  property :birth_year, Integer	# maybe Person was born in birth-Year
  has n, :entry	# Person entered Course of Event
end

class Punch
  include DataMapper::Resource

  property :punch_id, Serial	# Punch has Punch ID
  has n, :punch_placement, 'PunchPlacement'	# Punch is placed at Event Control
  has n, :visit	# Punch was visited by Entry at Time
end

class PunchPlacement
  include DataMapper::Resource

  property :event_control_event_id, Integer, :key => true	# Punch Placement is where Punch is placed at Event Control and Event Control is where Event includes Control Number and Event has Event ID
  property :event_control_number, Integer, :key => true	# Punch Placement is where Punch is placed at Event Control and Event Control is where Event includes Control Number
  belongs_to :event_control, 'EventControl', :child_key => [:event_control_number, :event_control_event_id], :parent_key => [:control_number, :event_id]	# Event_Control is involved in Punch Placement
  property :punch_id, Integer, :key => true	# Punch Placement is where Punch is placed at Event Control and Punch has Punch ID
  belongs_to :punch	# Punch is involved in Punch Placement
end

class Series
  include DataMapper::Resource

  property :series_id, Serial	# Series has Series ID
  property :name, String, :length => 40, :required => true	# Series has Series Name
  has n, :event	# Event is in Series
end

class Visit
  include DataMapper::Resource

  property :entry_id, Integer, :key => true	# Visit is where Punch was visited by Entry at Time and Entry has Entry ID
  belongs_to :entry	# Entry is involved in Visit
  property :punch_id, Integer, :key => true	# Visit is where Punch was visited by Entry at Time and Punch has Punch ID
  belongs_to :punch	# Punch is involved in Visit
  property :time, DateTime, :key => true	# Visit is where Punch was visited by Entry at Time
end

