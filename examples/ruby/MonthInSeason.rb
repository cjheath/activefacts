require 'activefacts/api'

module ::MonthInSeason

  class EventId < AutoCounter
    value_type 
  end

  class Month < String
    value_type 
    has_one :season                             # See Season.all_month
  end

  class Season < String
    value_type 
  end

  class Event
    identified_by :event_id
    one_to_one :event_id                        # See EventId.event
  end

  class Occurrence
    identified_by :event, :month
    has_one :event                              # See Event.all_occurrence
    has_one :month                              # See Month.all_occurrence
  end

end
