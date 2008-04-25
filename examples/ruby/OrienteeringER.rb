require 'activefacts/api'

module OrienteeringER

  class Accessibility < FixedLengthText
    value_type 
  end

  class ClubName < String
    value_type 
  end

  class Code < FixedLengthText
    value_type 
    one_to_one :club_name                       # See ClubName.code
  end

  class Control < UnsignedInteger
    value_type :length => 32
  end

  class Course < FixedLengthText
    value_type 
  end

  class Date < DateAndTime
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

  class SeriesEvent
    identified_by :event_number, :series_name
    has_one :series_name                        # See SeriesName.all_series_event
    has_one :event_number, Number               # See Number.all_series_event_by_event_number
  end

  class EventCourse
    identified_by :event, :course
    has_one :event                              # See Event.all_event_course
    has_one :course                             # See Course.all_event_course
  end

  class EventControl
    identified_by :event, :control
    has_one :point_value                        # See PointValue.all_event_control
    has_one :control                            # See Control.all_event_control
    has_one :event                              # See Event.all_event_control
  end

