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
    one_to_one :club_name
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
    has_one :series_name
    has_one :event_number, Number
  end

  class EventCourse
    identified_by :event, :course
    has_one :event
    has_one :course
  end

  class EventControl
    identified_by :event, :control
    has_one :point_value
    has_one :control
    has_one :event
  end

