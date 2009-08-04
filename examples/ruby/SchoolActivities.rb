require 'activefacts/api'

module ::SchoolActivities

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
    identified_by :activity_name
    one_to_one :activity_name, :mandatory       # See ActivityName.activity
  end

  class School
    identified_by :school_name
    one_to_one :school_name, :mandatory         # See SchoolName.school
  end

  class SchoolActivity
    identified_by :school, :activity
    has_one :activity, :mandatory               # See Activity.all_school_activity
    has_one :school, :mandatory                 # See School.all_school_activity
  end

  class Student
    identified_by :student_name
    has_one :school, :mandatory                 # See School.all_student
    one_to_one :student_name, :mandatory        # See StudentName.student
  end

  class StudentParticipation
    identified_by :student, :activity
    has_one :activity, :mandatory               # See Activity.all_student_participation
    has_one :school, :mandatory                 # See School.all_student_participation
    has_one :student, :mandatory                # See Student.all_student_participation
  end

end
