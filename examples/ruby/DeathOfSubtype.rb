require 'activefacts/api'

module DeathOfSubtype

  class CauseOfDeath < String
    value_type 
  end

  class Party_Id < AutoCounter
    value_type 
  end

  class Party
    identified_by :party_id
    one_to_one :party_id, Party_Id              # See Party_Id.party
  end

  class Person < Party
    maybe :is_dead
  end

  class Death
    identified_by :is_dead
    has_one :is_dead, Person                    # See Person.all_death_by_is_dead
    has_one :cause_of_death                     # See CauseOfDeath.all_death
  end

end
