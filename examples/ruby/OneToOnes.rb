require 'activefacts/api'

module ::OneToOnes

  class BoyID < AutoCounter
    value_type 
  end

  class GirlID < AutoCounter
    value_type 
  end

  class Boy
    identified_by :boy_id
    one_to_one :boy_id, BoyID                   # See BoyID.boy
  end

  class Girl
    identified_by :girl_id
    one_to_one :boy                             # See Boy.girl
    one_to_one :girl_id, GirlID                 # See GirlID.girl
  end

end
