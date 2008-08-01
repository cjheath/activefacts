vocabulary SchoolActivities;

/*
 * Value Types
 */
ActivityName is defined as VariableLengthText(32);
SchoolName is defined as VariableLengthText();
StudentName is defined as VariableLengthText();

/*
 * Entity Types
 */
Activity is identified by ActivityName where
	Activity has exactly one ActivityName,
	ActivityName is of at most one Activity;

School is identified by SchoolName where
	School has exactly one SchoolName,
	SchoolName is of at most one School;
SchoolActivity is where
	School sanctions Activity;

Student is identified by StudentName where
	Student has exactly one StudentName,
	StudentName is of at most one Student;
Student is enrolled in exactly one School;
StudentParticipation is where
	Student represents at most one School in Activity,
	Student participates in Activity which is sanctioned by School;

/*
 * Constraints:

Student represents School in Activity
	only if Student is enrolled in School;
Student represents School in Activity
	only if School sanctions Activity;

 */
