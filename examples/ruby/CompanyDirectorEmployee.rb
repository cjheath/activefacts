require 'activefacts/api'

module CompanyDirectorEmployee

  class CompanyName < String
    value_type :length => 48
  end

  class EmployeeNr < SignedInteger
    value_type :length => 32
  end

  class Name < String
    value_type :length => 48
  end

  class Company
    identified_by :company_name
    one_to_one :company_name                    # See CompanyName.company
    maybe :is_listed
  end

  class Meeting
    identified_by :date, :is_board_meeting, :company
    has_one :company                            # See Company.all_meeting
    has_one :date                               # See Date.all_meeting
    maybe :is_board_meeting
  end

  class Person
    identified_by :given_name, :family_name
    has_one :birth_date, Date                   # See Date.all_person_as_birth_date
    has_one :family_name, Name                  # See Name.all_person_as_family_name
    has_one :given_name, Name                   # See Name.all_person_as_given_name
  end

  class Attendance
    identified_by :attendee, :meeting
    has_one :attendee, Person                   # See Person.all_attendance_as_attendee
    has_one :meeting                            # See Meeting.all_attendance
  end

  class Directorship
    identified_by :director, :company
    has_one :company                            # See Company.all_directorship
    has_one :director, Person                   # See Person.all_directorship_as_director
    has_one :appointment_date, Date             # See Date.all_directorship_as_appointment_date
  end

  class Employee < Person
    identified_by :employee_nr
    has_one :company                            # See Company.all_employee
    one_to_one :employee_nr                     # See EmployeeNr.employee
    has_one :manager                            # See Manager.all_employee
  end

  class Manager < Employee
    maybe :is_ceo
  end

end
