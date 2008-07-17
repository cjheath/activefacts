require 'activefacts/api'

module CompanyDirector

  class CompanyName < String
    value_type 
  end

  class Name < String
    value_type :length => 48
  end

  class Company
    identified_by :company_name
    one_to_one :company_name                    # See CompanyName.company
  end

  class Meeting
    identified_by :date, :company
    has_one :company                            # See Company.all_meeting
    has_one :date                               # See Date.all_meeting
    maybe :is_board_meeting
  end

  class Person
    identified_by :family_name, :given_name
    has_one :birth_date, Date                   # See Date.all_person_by_birth_date
    has_one :family_name, Name                  # See Name.all_person_by_family_name
    has_one :given_name, Name                   # See Name.all_person_by_given_name
  end

  class Attendance
    identified_by :attendee, :meeting
    has_one :attendee, Person                   # See Person.all_attendance_by_attendee
    has_one :meeting                            # See Meeting.all_attendance
  end

  class Directorship
    identified_by :director, :company
    has_one :company                            # See Company.all_directorship
    has_one :director, Person                   # See Person.all_directorship_by_director
    has_one :appointment_date, Date             # See Date.all_directorship_by_appointment_date
  end

end
