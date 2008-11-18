vocabulary CompanyDirector;

/*
 * Value Types
 */
CompanyName is defined as VariableLengthText();
Name is defined as VariableLengthText(48);

/*
 * Entity Types
 */
Company is identified by its Name where
	Company is called CompanyName;

Meeting is identified by Date and Company where
	Meeting is held on exactly one Date,
	Meeting is of exactly one Company;
Meeting is board meeting;

Person is identified by family-Name and given-Name where
	Person has at most one family-Name,
	family-Name is of Person,
	Person has exactly one given-Name,
	given-Name is of Person;
Person was born on at most one birth-Date;
Attendance is where
	Person (as Attendee) attended Meeting,
	Meeting was attended by Attendee;
Directorship is where
	Person (as director) directs Company,
	Company is directed by at least one director;
Directorship began on exactly one appointment-Date;

