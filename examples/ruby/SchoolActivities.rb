require 'activefacts/api'

module SchoolActivities

  class ActivityName < String
    value_type :length => 32
  end

  class SchoolName < String
    value_type 
  end

  class StudentName < String
    value_type 
  end

  class Activity
    identified_by :name
    one_to_one :name, ActivityName
  end

  class School
    identified_by :school_name
    one_to_one :school_name
  end

  class SchoolActivity
    identified_by :school, :activity
    has_one :school
    has_one :activity
  end

  class Student
    identified_by :student_name
    one_to_one :student_name
    has_one :school
  end

  class StudentParticipation
    identified_by :student, :activity
    has_one :school
    has_one :student
    has_one :activity
  end

end
