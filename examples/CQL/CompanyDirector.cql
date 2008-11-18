vocabulary CompanyDirector;

/*
 * Value Types
 */
CompanyName is defined as VariableLengthText(48);
Name is defined as VariableLengthText(48);

/*
 * Entity Types
 */
Company is identified by its Name where
	Company is called CompanyName;
Meeting is where
	Company held meeting on Date;
Meeting is board meeting;

Person is identified by given-Name and family-Name where
	Person has exactly one given-Name,
	given-Name is of Person,
	family-Name is of Person,
	Person is called at most one family-Name;
Person was born on at most one birth-Date;
Attendance is where
	Person (as Attendee) attended Meeting,
	Meeting was attended by Attendee;
Directorship is where
	Person (as Director) directs Company,
	Company is directed by at least one Director;
Directorship began on exactly one appointment-Date;

