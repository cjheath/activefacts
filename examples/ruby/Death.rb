require 'activefacts/api'

module ::Death

  class CauseOfDeath < String
    value_type 
  end

  class PersonName < String
    value_type :length => 40
    one_to_one :person                          # See Person.person_name
  end

  class Person
    identified_by :person_name
    maybe :is_dead
    one_to_one :person_name, :mandatory => true  # See PersonName.person
  end

  class Death
    identified_by :person
    one_to_one :person, :mandatory => true      # See Person.death
    has_one :cause_of_death                     # See CauseOfDeath.all_death
  end

end
