require 'activefacts/api'

module ::Monogamy

  class Name < String
    value_type 
  end

  class PersonID < AutoCounter
    value_type 
    one_to_one :person                          # See Person.person_id
  end

  class Person
    identified_by :person_id
    has_one :name, :mandatory => true           # See Name.all_person
    one_to_one :person_id, :class => PersonID, :mandatory => true  # See PersonID.person
  end

  class Boy < Person
  end

  class Girl < Person
    one_to_one :boyfriend, :class => Boy, :counterpart => :girlfriend  # See Boy.girlfriend
  end

end
