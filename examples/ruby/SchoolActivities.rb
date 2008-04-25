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
    one_to_one :name, ActivityName              # See ActivityName.activity_by_name
  end

  class School
    identified_by :school_name
    one_to_one :school_name                     # See SchoolName.school
  end

  class SchoolActivity
    identified_by :school, :activity
    has_one :school                             # See School.all_school_activity
    has_one :activity                           # See Activity.all_school_activity
  end

  class Student
    identified_by :student_name
    one_to_one :student_name                    # See StudentName.student
    has_one :school                             # See School.all_student
  end

  class StudentParticipation
    identified_by :student, :activity
    has_one :school                             # See School.all_student_participation
    has_one :student                            # See Student.all_student_participation
    has_one :activity                           # See Activity.all_student_participation
  end

end
