require 'activefacts/api'

module ::MultiInheritance

  class EmployeeID < AutoCounter
    value_type 
    one_to_one :employee                        # See Employee.employee_id
  end

  class PersonName < String
    value_type 
    one_to_one :person                          # See Person.person_name
  end

  class TFN < Char
    value_type :length => 9
    one_to_one :australian, :mandatory => true  # See Australian.tfn
  end

  class Person
    identified_by :person_name
    one_to_one :person_name, :mandatory => true  # See PersonName.person
  end

  class Australian < Person
    one_to_one :tfn, :class => TFN              # See TFN.australian
  end

  class Employee < Person
    identified_by :employee_id
    one_to_one :employee_id, :class => EmployeeID, :mandatory => true  # See EmployeeID.employee
  end

  class AustralianEmployee < Employee
    supertypes Australian
  end

end
