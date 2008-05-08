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
Activity = entity identified by Name:
	Activity has exactly one ActivityName (as Name),
	Name is of at most one Activity;

School = entity identified by SchoolName:
	School has exactly one SchoolName,
	SchoolName is of at most one School;
SchoolActivity = School sanctions Activity;

Student = entity identified by StudentName:
	Student has exactly one StudentName,
	StudentName is of at most one Student;
Student is enrolled in exactly one School;
StudentParticipation = Student represents at most one School in Activity,
	Student participates in Activity which is sanctioned by School;

/*
Constraints:
	REVISIT: Verbalise SubsetConstraint StudentParticipationIsForEnrolledSchool REVISIT: Unhandled constraint type
	REVISIT: Verbalise SubsetConstraint StudentParticipationIsForSchoolSanctionedActivity REVISIT: Unhandled constraint type
 */
