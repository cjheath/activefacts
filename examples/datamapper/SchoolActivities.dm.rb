require 'dm-core'
require 'dm-constraints'

class SchoolActivity
  include DataMapper::Resource

  property :activity_name, String, :length => 32, :key => true	# School Activity is where School sanctions Activity and Activity has Activity Name
  property :school_name, String, :key => true	# School Activity is where School sanctions Activity and School has School Name
end

class Student
  include DataMapper::Resource

  property :school_name, String, :required => true	# Student is enrolled in School and School has School Name
  property :student_name, String, :key => true	# Student has Student Name
  has n, :student_participation, 'StudentParticipation'	# Student represents School in Activity
end

class StudentParticipation
  include DataMapper::Resource

  property :activity_name, String, :length => 32, :key => true	# Student Participation is where Student represents School in Activity and Activity has Activity Name
  property :school_name, String, :key => true	# Student Participation is where Student represents School in Activity and School has School Name
  property :student_name, String, :key => true	# Student Participation is where Student represents School in Activity and Student has Student Name
  belongs_to :student	# Student is involved in Student Participation
end

