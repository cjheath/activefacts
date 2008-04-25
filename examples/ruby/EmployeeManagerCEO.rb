require 'activefacts/api'

module EmployeeManagerCEO

  class PersonName < String
    value_type 
  end

  class Person
    identified_by :person_name
    one_to_one :person_name                     # See PersonName.person
    maybe :is_manager
  end

  class Employee < Person
    has_one :manager                            # See Manager.all_employee
  end

  class Manager < Person
    maybe :is_ceo
  end

  class CEO < Manager
  end

end
