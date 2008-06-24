vocabulary CompanyDirector;

/*
 * Value Types
 */
CompanyName is defined as VariableLengthText(48);
Date is defined as Date();
Name is defined as VariableLengthText(48);

/*
 * Entity Types
 */
Company is identified by CompanyName:
	Company is called exactly one CompanyName,
	CompanyName is of at most one Company;
Meeting is where
	Company held meeting on Date;
Meeting is board meeting;

Person is identified by given-Name and family-Name:
	Person has exactly one given-Name,
	given-Name is of Person,
	family-Name is of Person,
	Person is called at most one family-Name;
Directorship is where
	Person (as Director) directs Company,
	Company is directed by at least one Director;
Person was born on at most one birth-Date;
Attendance is where
	Person (as Attendee) attended Meeting,
	Meeting was attended by Attendee;
Directorship began on exactly one appointment-Date;

