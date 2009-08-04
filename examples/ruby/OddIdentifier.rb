require 'activefacts/api'

module ::OddIdentifier

  class Ordinal < SignedInteger
    value_type :length => 32
  end

  class Text < String
    value_type 
  end

  class ThingID < AutoCounter
    value_type 
  end

  class Thing
    identified_by :thing_id
    one_to_one :thing_id, ThingID, :mandatory   # See ThingID.thing
  end

  class ThingSequence
    identified_by :thing, :text
    has_one :ordinal, :mandatory                # See Ordinal.all_thing_sequence
    has_one :thing, :mandatory                  # See Thing.all_thing_sequence
    has_one :text, :mandatory                   # See Text.all_thing_sequence
  end

end
