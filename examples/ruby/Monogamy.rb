require 'activefacts/api'

module Monogamy

  class Name < String
    value_type 
  end

  class PersonID < AutoCounter
    value_type 
  end

  class Person
    identified_by :person_id
    has_one :name                               # See Name.all_person
    one_to_one :person_id, PersonID             # See PersonID.person_by_person_id
  end

  class Boy < Person
  end

  class Girl < Person
    one_to_one :boyfriend, Boy, :girlfriend     # See Boy.girlfriend_by_boyfriend
  end

end
