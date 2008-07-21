require 'activefacts/api'

module EmployeeManagerCEO

  class PersonName < String
    value_type 
  end

  class Person
    identified_by :person_name
    one_to_one :person_name                     # See PersonName.person
  end

  class Employee < Person
    maybe :is_manager
    has_one :manager                            # See Manager.all_employee
  end

  class Manager < Employee
    maybe :is_ceo
  end

  class CEO < Manager
  end

end
