require 'activefacts/api'

module ::MultiInheritance

  class EmployeeID < AutoCounter
    value_type 
  end

  class PersonName < String
    value_type 
  end

  class TFN < FixedLengthText
    value_type :length => 9
  end

  class Person
    identified_by :person_name
    one_to_one :person_name                     # See PersonName.person
  end

  class Australian < Person
    one_to_one :tfn, TFN                        # See TFN.australian
  end

  class Employee < Person
    identified_by :employee_id
    one_to_one :employee_id, EmployeeID         # See EmployeeID.employee
  end

  class AustralianEmployee < Employee
    supertypes Australian
  end

end
