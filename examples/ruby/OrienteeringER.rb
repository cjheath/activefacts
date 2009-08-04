require 'activefacts/api'

module ::OrienteeringER

  class Accessibility < FixedLengthText
    value_type 
  end

  class ClubName < String
    value_type 
  end

  class Code < FixedLengthText
    value_type 
  end

  class Control < UnsignedInteger
    value_type :length => 32
  end

  class Course < FixedLengthText
    value_type 
  end

  class DateAndTime < ::DateTime
    value_type 
  end

  class Date < ::DateTime
    value_type 
  end

  class EventName < String
    value_type 
  end

  class ID < AutoCounter
    value_type 
  end

  class Location < String
    value_type 
  end

  class Name < String
    value_type 
  end

  class Number < SignedInteger
    value_type :length => 32
  end

  class PointValue < UnsignedInteger
    value_type :length => 32
  end

  class SeriesName < String
    value_type 
  end

  class Club
    identified_by :code
    one_to_one :club_name, :mandatory           # See ClubName.club
    one_to_one :code, :mandatory                # See Code.club
  end

  class Map
    identified_by :map_name
    has_one :accessibility, :mandatory          # See Accessibility.all_map
    has_one :club, :mandatory                   # See Club.all_map
    one_to_one :map_name, Name, :mandatory      # See Name.map_as_map_name
  end

  class SeriesEvent
    identified_by :series_name, :event_number
    has_one :event_number, Number, :mandatory   # See Number.all_series_event_as_event_number
    has_one :series_name, :mandatory            # See SeriesName.all_series_event
  end

  class Event
    identified_by :event_id
    has_one :club, :mandatory                   # See Club.all_event
    has_one :date, :mandatory                   # See Date.all_event
    one_to_one :event_id, ID, :mandatory        # See ID.event_as_event_id
    one_to_one :event_name, :mandatory          # See EventName.event
    has_one :location, :mandatory               # See Location.all_event
    has_one :map, :mandatory                    # See Map.all_event
    one_to_one :series_event, :mandatory        # See SeriesEvent.event
  end

  class EventControl
    identified_by :event, :control
    has_one :control, :mandatory                # See Control.all_event_control
    has_one :event, :mandatory                  # See Event.all_event_control
    has_one :point_value, :mandatory            # See PointValue.all_event_control
  end

  class EventCourse
    identified_by :course, :event
    has_one :course, :mandatory                 # See Course.all_event_course
    has_one :event, :mandatory                  # See Event.all_event_course
  end

end
