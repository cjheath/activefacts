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
Activity is identified by its Name;

School is identified by its Name;
SchoolActivity is where
	School sanctions Activity;

Student is identified by its Name;
Student is enrolled in exactly one School;
StudentParticipation is where
	Student represents at most one School in Activity,
	Student participates in Activity which is sanctioned by School;

/*
 * Constraints:
 */
Student represents School in Activity
	only if School sanctions Activity;
Student represents School in Activity
	only if Student is enrolled in School;
