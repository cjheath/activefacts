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
Activity is identified by Name:
	Activity has exactly one ActivityName (as Name),
	Name is of at most one Activity;

School is identified by SchoolName:
	School has exactly one SchoolName,
	SchoolName is of at most one School;
SchoolActivity is where
	School sanctions Activity;

Student is identified by StudentName:
	Student has exactly one StudentName,
	StudentName is of at most one Student;
Student is enrolled in exactly one School;
StudentParticipation is where
	Student represents at most one School in Activity,
	Student participates in Activity which is sanctioned by School;

/*
Constraints:
	REVISIT: Verbalise SubsetConstraint StudentParticipationIsForEnrolledSchool REVISIT: Unhandled constraint type
	REVISIT: Verbalise SubsetConstraint StudentParticipationIsForSchoolSanctionedActivity REVISIT: Unhandled constraint type
 */
