require 'activefacts/api'

module CompanyDirector

  class CompanyName < String
    value_type :length => 48
  end

  class Date < ::Date
    value_type 
  end

  class Name < String
    value_type :length => 48
  end

  class Company
    identified_by :company_name
    one_to_one :company_name
  end

  class Meeting
    identified_by :date, :company
    has_one :company
    has_one :date
    maybe :is_board_meeting
  end

  class Person
    identified_by :given_name, :family_name
    has_one :given_name, Name
    has_one :birth_date, Date
    has_one :family_name, Name
  end

  class Directorship
    identified_by :director, :company
    has_one :director, Person
    has_one :company
    has_one :appointment_date, Date
  end

  class Attendance
    identified_by :meeting, :attendee
    has_one :attendee, Person
    has_one :meeting
  end

end
