require 'activefacts/api'

module Marriage

  class Name < String
    value_type 
  end

  class Person
    identified_by :given_name, :family_name
    has_one :family_name, Name                  # See Name.all_person_by_family_name
    has_one :given_name, Name                   # See Name.all_person_by_given_name
  end

  class Marriage
    identified_by :husband, :wife
    has_one :husband, Person                    # See Person.all_marriage_by_husband
    has_one :wife, Person                       # See Person.all_marriage_by_wife
  end

end
