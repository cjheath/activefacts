require 'activefacts/api'

module MultiInheritance

  class EmployeeID < AutoCounter
    value_type 
  end

  class PersonName < String
    value_type 
  end

  class Person
    identified_by :person_name
    one_to_one :person_name                     # See PersonName.person
  end

  class Australian < Person
  end

  class Employee < Person
    identified_by :employee_i_d
    one_to_one :employee_i_d                    # See EmployeeID.employee
  end

  class AustralianEmployee < Australian
  end

end
