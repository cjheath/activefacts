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
    identified_by :company_name
    one_to_one :company_name
  end

  class Person
    identified_by :person_name
    one_to_one :person_name
    has_one :birth_date, Date
  end

  class Attendance	# Implicitly Objectified Fact Type
    identified_by :date, :company, :person
    has_one :company
    has_one :date
    has_one :person
  end

  class Directorship
    identified_by :person, :company
    has_one :person
    has_one :company
    has_one :appointment_date, Date
  end

end
