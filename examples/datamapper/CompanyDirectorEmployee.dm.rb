require 'dm-core'
require 'dm-constraints'

class Attendance
  include DataMapper::Resource

  property :meeting_company_name, String, :length => 48, :key => true	# Attendance is where Person attended Meeting and Company held Meeting and Company is called Company Name
  property :meeting_date, DateTime, :key => true	# Attendance is where Person attended Meeting and Meeting is held on Date
  property :meeting_is_board_meeting, Boolean, :key => true	# Attendance is where Person attended Meeting and Meeting is board meeting
  belongs_to :meeting, :child_key => [:meeting_company_name, :meeting_date, :meeting_is_board_meeting], :parent_key => [:company_name, :date, :is_board_meeting]	# Meeting is involved in Attendance
  property :attendee_family_name, String, :length => 48, :key => true	# Attendance is where Person attended Meeting and maybe family-Name is of Person
  property :attendee_given_name, String, :length => 48, :key => true	# Attendance is where Person attended Meeting and Person has given-Name
  belongs_to :attendee, 'Person', :child_key => [:attendee_family_name, :attendee_given_name], :parent_key => [:family_name, :given_name]	# Attendee is involved in Attendance
end

class Company
  include DataMapper::Resource

  property :is_listed, Boolean	# Company is listed
  property :company_name, String, :length => 48, :key => true	# Company is called Company Name
  has n, :directorship	# Person directs Company
  has n, :employee	# Employee works at Company
  has n, :meeting	# Company held Meeting
end

class Directorship
  include DataMapper::Resource

  property :company_name, String, :length => 48, :key => true	# Directorship is where Person directs Company and Company is called Company Name
  belongs_to :company	# Company is involved in Directorship
  property :appointment_date, DateTime, :required => true	# Directorship began on appointment-Date
  property :director_family_name, String, :length => 48, :key => true	# Directorship is where Person directs Company and maybe family-Name is of Person
  property :director_given_name, String, :length => 48, :key => true	# Directorship is where Person directs Company and Person has given-Name
  belongs_to :director, 'Person', :child_key => [:director_family_name, :director_given_name], :parent_key => [:family_name, :given_name]	# Director is involved in Directorship
end

class Meeting
  include DataMapper::Resource

  property :is_board_meeting, Boolean, :key => true	# Meeting is board meeting
  property :company_name, String, :length => 48, :key => true	# Company held Meeting and Company is called Company Name
  belongs_to :company	# Company held Meeting
  property :date, DateTime, :key => true	# Meeting is held on Date
  has n, :attendance, :child_key => [:meeting_company_name, :meeting_date, :meeting_is_board_meeting], :parent_key => [:company_name, :date, :is_board_meeting]	# Person attended Meeting
end

class Person
  include DataMapper::Resource

  property :birth_date, DateTime	# maybe Person was born on birth-Date
  property :given_name, String, :length => 48, :key => true	# Person has given-Name
  property :family_name, String, :length => 48, :key => true	# maybe family-Name is of Person
  has n, :attendance_as_attendee, 'Attendance', :child_key => [:attendee_family_name, :attendee_given_name], :parent_key => [:family_name, :given_name]	# Person attended Meeting
  has n, :directorship_as_director, 'Directorship', :child_key => [:director_family_name, :director_given_name], :parent_key => [:family_name, :given_name]	# Person directs Company
end

class Employee < Person
  property :company_name, String, :length => 48, :required => true	# Employee works at Company and Company is called Company Name
  belongs_to :company	# Employee works at Company
  property :employee_nr, Integer, :key => true	# Employee has Employee Nr
  property :manager_nr, Integer	# maybe Employee is supervised by Manager and Employee has Employee Nr
  belongs_to :manager, :child_key => [:manager_nr], :parent_key => [:employee_nr]	# Employee is supervised by Manager
end

class Manager < Employee
  property :is_ceo, Boolean	# Manager is ceo
  has n, :employee, :child_key => [:manager_nr], :parent_key => [:employee_nr]	# Employee is supervised by Manager
end

