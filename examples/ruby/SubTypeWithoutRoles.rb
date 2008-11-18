require 'activefacts/api'

module SubTypeWithoutRoles

  class ThingID < AutoCounter
    value_type 
  end

  class Thing
    identified_by :thing_id
    one_to_one :thing_id, ThingID               # See ThingID.thing_by_thing_id
  end

  class Thong < Thing
  end

end
