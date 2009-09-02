require 'activefacts/api'

module ::Orienteering

  class Accessibility < FixedLengthText
    value_type :length => 1
    restrict 'A'..'D'
  end

  class ClubCode < String
    value_type :length => 6
  end

  class ClubName < String
    value_type :length => 32
  end

  class ControlNumber < UnsignedInteger
    value_type :length => 32
    restrict 1..1000
  end

  class Course < String
    value_type :length => 16
    restrict 'A'..'E', 'PW'
  end

  class DateAndTime < ::DateTime
    value_type 
  end

  class EntryID < AutoCounter
    value_type 
  end

  class EventID < AutoCounter
    value_type 
  end

  class EventName < String
    value_type :length => 50
  end

  class FamilyName < String
    value_type :length => 48
  end

  class Gender < FixedLengthText
    value_type :length => 1
    restrict 'M', 'F'
  end

  class GivenName < String
    value_type :length => 48
  end

  class Location < String
    value_type :length => 200
  end

  class MapID < AutoCounter
    value_type 
  end

  class MapName < String
    value_type :length => 80
  end

  class Number < UnsignedInteger
    value_type :length => 32
    restrict 1..100
  end

  class PersonID < AutoCounter
    value_type 
  end

  class Placing < UnsignedInteger
    value_type :length => 32
  end

  class PointValue < UnsignedInteger
    value_type :length => 32
  end

  class PostCode < UnsignedInteger
    value_type :length => 32
  end

  class PunchID < AutoCounter
    value_type 
  end

  class Score < SignedInteger
    value_type :length => 32
  end

  class ScoringMethod < String
    value_type :length => 32
    restrict 'Score', 'Scatter', 'Special'
  end

  class SeriesID < AutoCounter
    value_type 
  end

  class SeriesName < String
    value_type :length => 40
  end

  class StartTime < ::DateTime
    value_type 
  end

  class Time < ::DateTime
    value_type 
  end

  class Year < UnsignedInteger
    value_type :length => 32
    restrict 1900..3000
  end

  class Club
    identified_by :club_code
    one_to_one :club_code, :mandatory => true   # See ClubCode.club
    one_to_one :club_name, :mandatory => true   # See ClubName.club
  end

  class Event
    identified_by :event_id
    has_one :club, :mandatory => true           # See Club.all_event
    one_to_one :event_id, :class => EventID, :mandatory => true  # See EventID.event
    one_to_one :event_name                      # See EventName.event
    has_one :map, :mandatory => true            # See Map.all_event
    has_one :number                             # See Number.all_event
    has_one :series                             # See Series.all_event
    has_one :start_location, :class => Location, :mandatory => true  # See Location.all_event_as_start_location
    has_one :start_time, :mandatory => true     # See StartTime.all_event
  end

  class EventControl
    identified_by :event, :control_number
    has_one :control_number, :mandatory => true  # See ControlNumber.all_event_control
    has_one :event, :mandatory => true          # See Event.all_event_control
    has_one :point_value                        # See PointValue.all_event_control
  end

  class EventScoringMethod
    identified_by :course, :event
    has_one :course, :mandatory => true         # See Course.all_event_scoring_method
    has_one :event, :mandatory => true          # See Event.all_event_scoring_method
    has_one :scoring_method, :mandatory => true  # See ScoringMethod.all_event_scoring_method
  end

  class Map
    identified_by :map_id
    has_one :accessibility                      # See Accessibility.all_map
    one_to_one :map_id, :class => MapID, :mandatory => true  # See MapID.map
    one_to_one :map_name, :mandatory => true    # See MapName.map
    has_one :owner, :class => Club, :mandatory => true  # See Club.all_map_as_owner
  end

  class Person
    identified_by :person_id
    has_one :birth_year, :class => Year         # See Year.all_person_as_birth_year
    has_one :club                               # See Club.all_person
    has_one :family_name, :mandatory => true    # See FamilyName.all_person
    has_one :gender                             # See Gender.all_person
    has_one :given_name, :mandatory => true     # See GivenName.all_person
    one_to_one :person_id, :class => PersonID, :mandatory => true  # See PersonID.person
    has_one :post_code                          # See PostCode.all_person
  end

  class Punch
    identified_by :punch_id
    one_to_one :punch_id, :class => PunchID, :mandatory => true  # See PunchID.punch
  end

  class PunchPlacement
    identified_by :punch, :event_control
    has_one :event_control, :mandatory => true  # See EventControl.all_punch_placement
    has_one :punch, :mandatory => true          # See Punch.all_punch_placement
  end

  class Series
    identified_by :series_id
    one_to_one :name, :class => SeriesName, :mandatory => true  # See SeriesName.series_as_name
    one_to_one :series_id, :class => SeriesID, :mandatory => true  # See SeriesID.series
  end

  class Entry
    identified_by :entry_id
    has_one :course, :mandatory => true         # See Course.all_entry
    has_one :event, :mandatory => true          # See Event.all_entry
    has_one :person, :mandatory => true         # See Person.all_entry
    one_to_one :entry_id, :class => EntryID, :mandatory => true  # See EntryID.entry
    has_one :finish_placing, :class => Placing  # See Placing.all_entry_as_finish_placing
    has_one :score                              # See Score.all_entry
  end

  class Visit
    identified_by :punch, :entry, :time
    has_one :entry, :mandatory => true          # See Entry.all_visit
    has_one :punch, :mandatory => true          # See Punch.all_visit
    has_one :time, :mandatory => true           # See Time.all_visit
  end

end
