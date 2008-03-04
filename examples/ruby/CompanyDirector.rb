require 'activefacts/api'

module CompanyDirector

  class CompanyName < String
    value_type :length => 48
  end

  class Date < ::Date
    value_type 
  end

  class PersonName < String
    value_type :length => 48
  end

  class Company
    entity_type :company_name
    binary :company_name, CompanyName, 1, :company
  end

  class Person
    entity_type :person_name
    binary :person_name, PersonName, 1, :person
    binary :birth_date, Date, :person
  end

  class Attendance	# Implicitly Objectified Fact Type
    entity_type :date, :company, :person
    binary :company, Company
    binary :date, Date
    binary :person, Person
  end

  class Directorship
    entity_type :person, :company
    binary :person, Person
    binary :company, Company
    binary :appointment_date, Date, :directorship
  end

end
