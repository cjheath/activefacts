require 'activefacts/api'

module ::Marriage

  class Name < String
    value_type 
  end

  class Person
    identified_by :given_name, :family_name
    has_one :family_name, Name, :mandatory      # See Name.all_person_as_family_name
    has_one :given_name, Name, :mandatory       # See Name.all_person_as_given_name
  end

  class Marriage
    identified_by :husband, :wife
    has_one :husband, Person, :mandatory        # See Person.all_marriage_as_husband
    has_one :wife, Person, :mandatory           # See Person.all_marriage_as_wife
  end

end
