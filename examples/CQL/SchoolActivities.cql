vocabulary SchoolActivities;

/*
 * Value Types
 */
ActivityName = VariableLengthText(32);
SchoolName = VariableLengthText();
StudentName = VariableLengthText();

/*
 * Entity Types
 */
Activity = entity known by ActivityName:
	Activity has exactly one ActivityName,
	ActivityName is of at most one Activity;

School = entity known by SchoolName:
	School has exactly one SchoolName,
	SchoolName is of at most one School;
SchoolActivity = School sanctions Activity;

Student = entity known by StudentName:
	Student has exactly one StudentName,
	StudentName is of at most one Student;
Student is enrolled in exactly one School;
StudentParticipation = Student represents at most one School in Activity,
	Student participates in Activity which is sanctioned by School;

/*
Constraints:
	SubsetConstraint StudentParticipationIsForEnrolledSchool StudentIsEnrolledInSchool(School, Student) < StudentParticipation(School, Student)
	SubsetConstraint StudentParticipationIsForSchoolSanctionedActivity SchoolActivity(School, Activity) < StudentParticipation(School, Activity)
 */
