require 'activefacts/api'

module Death

  class CauseOfDeath < String
    value_type 
  end

  class PersonName < String
    value_type :length => 40
  end

  class Person
    identified_by :person_name
    maybe :is_dead
    one_to_one :person_name                     # See PersonName.person
  end

  class Death
    identified_by :is_dead
    has_one :is_dead, Person                    # See Person.all_death_by_is_dead
    has_one :cause_of_death                     # See CauseOfDeath.all_death
  end

end
