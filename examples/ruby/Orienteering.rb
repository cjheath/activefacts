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
    one_to_one :club_name
    one_to_one :club_code
  end

  class Event
    identified_by :event_i_d
    one_to_one :event_name
    has_one :map
    has_one :start_location, Location
    one_to_one :event_i_d
    has_one :start_time
    has_one :series
    has_one :number
    has_one :club
  end

  class EventScoringMethod
    identified_by :course, :event
    has_one :scoring_method
    has_one :course
    has_one :event
  end

  class EventControl
    identified_by :control_number, :event
    has_one :event
    has_one :control_number
    has_one :point_value
  end

  class Map
    identified_by :map_i_d
    one_to_one :map_name
    has_one :owner, Club
    has_one :accessibility
    one_to_one :map_i_d
  end

  class Person
    identified_by :person_i_d
    has_one :family_name
    has_one :given_name
    has_one :gender
    has_one :birth_year, Year
    has_one :post_code
    has_one :club
    one_to_one :person_i_d
  end

  class Entry
    identified_by :entry_i_d
    has_one :person
    has_one :course
    has_one :event
    has_one :score
    has_one :finish_placing, Placing
    one_to_one :entry_i_d
  end

  class Punch
    identified_by :punch_i_d
    one_to_one :punch_i_d
  end

  class Visit
    identified_by :punch, :entry, :time
    has_one :punch
    has_one :entry
    has_one :time
  end

  class PunchPlacement
    identified_by :event_control, :punch
    has_one :punch
    has_one :event_control
  end

  class Series
    identified_by :series_i_d
    one_to_one :name, SeriesName
    one_to_one :series_i_d
  end

end
