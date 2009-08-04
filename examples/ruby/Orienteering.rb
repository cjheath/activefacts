require 'activefacts/api'

module ::Orienteering

  class Accessibility < FixedLengthText
    value_type :length => 1
    # REVISIT: Accessibility has restricted values
  end

  class ClubCode < String
    value_type :length => 6
  end

  class ClubName < String
    value_type :length => 32
  end

  class ControlNumber < UnsignedInteger
    value_type :length => 32
    # REVISIT: ControlNumber has restricted values
  end

  class Course < String
    value_type :length => 16
    # REVISIT: Course has restricted values
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
    # REVISIT: Gender has restricted values
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
    # REVISIT: Number has restricted values
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
    # REVISIT: ScoringMethod has restricted values
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
    # REVISIT: Year has restricted values
  end

  class Club
    identified_by :club_code
    one_to_one :club_code, :mandatory           # See ClubCode.club
    one_to_one :club_name, :mandatory           # See ClubName.club
  end

  class Event
    identified_by :event_id
    has_one :club, :mandatory                   # See Club.all_event
    one_to_one :event_id, EventID, :mandatory   # See EventID.event
    one_to_one :event_name                      # See EventName.event
    has_one :map, :mandatory                    # See Map.all_event
    has_one :number                             # See Number.all_event
    has_one :series                             # See Series.all_event
    has_one :start_location, Location, :mandatory  # See Location.all_event_as_start_location
    has_one :start_time, :mandatory             # See StartTime.all_event
  end

  class EventControl
    identified_by :event, :control_number
    has_one :control_number, :mandatory         # See ControlNumber.all_event_control
    has_one :event, :mandatory                  # See Event.all_event_control
    has_one :point_value                        # See PointValue.all_event_control
  end

  class EventScoringMethod
    identified_by :course, :event
    has_one :course, :mandatory                 # See Course.all_event_scoring_method
    has_one :event, :mandatory                  # See Event.all_event_scoring_method
    has_one :scoring_method, :mandatory         # See ScoringMethod.all_event_scoring_method
  end

  class Map
    identified_by :map_id
    has_one :accessibility                      # See Accessibility.all_map
    one_to_one :map_id, MapID, :mandatory       # See MapID.map
    one_to_one :map_name, :mandatory            # See MapName.map
    has_one :owner, Club, :mandatory            # See Club.all_map_as_owner
  end

  class Person
    identified_by :person_id
    has_one :birth_year, Year                   # See Year.all_person_as_birth_year
    has_one :club                               # See Club.all_person
    has_one :family_name, :mandatory            # See FamilyName.all_person
    has_one :gender                             # See Gender.all_person
    has_one :given_name, :mandatory             # See GivenName.all_person
    one_to_one :person_id, PersonID, :mandatory  # See PersonID.person
    has_one :post_code                          # See PostCode.all_person
  end

  class Punch
    identified_by :punch_id
    one_to_one :punch_id, PunchID, :mandatory   # See PunchID.punch
  end

  class PunchPlacement
    identified_by :punch, :event_control
    has_one :event_control, :mandatory          # See EventControl.all_punch_placement
    has_one :punch, :mandatory                  # See Punch.all_punch_placement
  end

  class Series
    identified_by :series_id
    one_to_one :name, SeriesName, :mandatory    # See SeriesName.series_as_name
    one_to_one :series_id, SeriesID, :mandatory  # See SeriesID.series
  end

  class Entry
    identified_by :entry_id
    has_one :course, :mandatory                 # See Course.all_entry
    has_one :event, :mandatory                  # See Event.all_entry
    has_one :person, :mandatory                 # See Person.all_entry
    one_to_one :entry_id, EntryID, :mandatory   # See EntryID.entry
    has_one :finish_placing, Placing            # See Placing.all_entry_as_finish_placing
    has_one :score                              # See Score.all_entry
  end

  class Visit
    identified_by :punch, :entry, :time
    has_one :entry, :mandatory                  # See Entry.all_visit
    has_one :punch, :mandatory                  # See Punch.all_visit
    has_one :time, :mandatory                   # See Time.all_visit
  end

end
