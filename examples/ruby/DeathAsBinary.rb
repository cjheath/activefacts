require 'activefacts/api'

module DeathAsBinary

  class CauseOfDeath < String
    value_type 
  end

  class PersonName < String
    value_type 
  end

  class Person
    identified_by :person_name
    one_to_one :person_name                     # See PersonName.person
  end

  class Death
    identified_by :person
    has_one :cause_of_death                     # See CauseOfDeath.all_death
    one_to_one :person                          # See Person.death
  end

end
