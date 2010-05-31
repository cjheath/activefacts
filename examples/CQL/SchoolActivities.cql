vocabulary SchoolActivities;

/*
 * Value Types
 */
Activity Name is written as Variable Length Text(32);
School Name is written as Variable Length Text;
Student Name is written as Variable Length Text;

/*
 * Entity Types
 */
Activity is identified by its Name;

School is identified by its Name;

School Activity is where
	School sanctions Activity;

Student is identified by its Name;
Student is enrolled in one School;

Student Participation is where
	Student represents School in Activity,
	Student participates in Activity which is sanctioned by at most one School;

/*
 * Constraints:
 */
Student represents School in Activity
	only if School sanctions Activity;
Student represents School in Activity
	only if Student is enrolled in School;
