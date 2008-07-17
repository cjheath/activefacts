require 'activefacts/api'

module ObjectifiedUnary

  class CauseOfDeath < String
    value_type 
  end

  class PersonName < String
    value_type :length => 40
  end

  class Person
    identified_by :person_name
    maybe :death_role
    one_to_one :person_name                     # See PersonName.person
  end
