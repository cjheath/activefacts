require 'activefacts/api'

module MultiInheritance

  class Employee_ID < AutoCounter
    value_type 
  end

  class Person_Name < String
    value_type 
  end

  class Person
    identified_by :person_name
    one_to_one :person_name, Person_Name
  end

  class Australian < Person
  end

  class Employee < Person
    identified_by :employee_i_d
    one_to_one :employee_i_d, Employee_ID
  end

  class AustralianEmployee < Australian
  end

end
