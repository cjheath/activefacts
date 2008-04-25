require 'activefacts/api'

module Orienteering

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

  class StartTime < DateAndTime
    value_type 
  end

  class Time < DateAndTime
    value_type 
  end

  class Year < UnsignedInteger
    value_type :length => 32
    # REVISIT: Year has restricted values
  end

  class Club
    identified_by :club_code
    one_to_one :club_name                       # See ClubName.club
    one_to_one :club_code                       # See ClubCode.club
  end

  class Event
    identified_by :event_i_d
    one_to_one :event_name                      # See EventName.event
    has_one :map                                # See Map.all_event
    has_one :start_location, Location           # See Location.all_event_by_start_location
    one_to_one :event_i_d                       # See EventID.event
    has_one :start_time                         # See StartTime.all_event
    has_one :series                             # See Series.all_event
    has_one :number                             # See Number.all_event
    has_one :club                               # See Club.all_event
  end

  class EventScoringMethod
    identified_by :course, :event
    has_one :scoring_method                     # See ScoringMethod.all_event_scoring_method
    has_one :course                             # See Course.all_event_scoring_method
    has_one :event                              # See Event.all_event_scoring_method
  end

  class EventControl
    identified_by :control_number, :event
    has_one :event                              # See Event.all_event_control
    has_one :control_number                     # See ControlNumber.all_event_control
    has_one :point_value                        # See PointValue.all_event_control
  end

  class Map
    identified_by :map_i_d
    one_to_one :map_name                        # See MapName.map
    has_one :owner, Club                        # See Club.all_map_by_owner
    has_one :accessibility                      # See Accessibility.all_map
    one_to_one :map_i_d                         # See MapID.map
  end

  class Person
    identified_by :person_i_d
    has_one :family_name                        # See FamilyName.all_person
    has_one :given_name                         # See GivenName.all_person
    has_one :gender                             # See Gender.all_person
    has_one :birth_year, Year                   # See Year.all_person_by_birth_year
    has_one :post_code                          # See PostCode.all_person
    has_one :club                               # See Club.all_person
    one_to_one :person_i_d                      # See PersonID.person
  end

  class Entry
    identified_by :entry_i_d
    has_one :person                             # See Person.all_entry
    has_one :course                             # See Course.all_entry
    has_one :event                              # See Event.all_entry
    has_one :score                              # See Score.all_entry
    has_one :finish_placing, Placing            # See Placing.all_entry_by_finish_placing
    one_to_one :entry_i_d                       # See EntryID.entry
  end

  class Punch
    identified_by :punch_i_d
    one_to_one :punch_i_d                       # See PunchID.punch
  end

  class Visit
    identified_by :punch, :entry, :time
    has_one :punch                              # See Punch.all_visit
    has_one :entry                              # See Entry.all_visit
    has_one :time                               # See Time.all_visit
  end

  class PunchPlacement
    identified_by :event_control, :punch
    has_one :punch                              # See Punch.all_punch_placement
    has_one :event_control                      # See EventControl.all_punch_placement
  end

  class Series
    identified_by :series_i_d
    one_to_one :name, SeriesName                # See SeriesName.series_by_name
    one_to_one :series_i_d                      # See SeriesID.series
  end

end
