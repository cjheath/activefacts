vocabulary CompanyDirector;

/*
 * Value Types
 */
CompanyName = VariableLengthText(48);
Date = Date();
Name = VariableLengthText(48);

/*
 * Entity Types
 */
Company = entity identified by CompanyName:
	Company is called exactly one CompanyName,
	CompanyName is of at most one Company;
Meeting = Company held meeting on Date;
Meeting is board meeting;

Person = entity identified by given-Name and family-Name:
	Person has exactly one given-Name,
	given-Name is of Person,
	family-Name is of Person,
	Person is called at most one family-Name;
Directorship = Person (as Director) directs Company,
	Company is directed by at least one Director;
Person was born on at most one birth-Date;
Attendance = Person (as Attendee) attended Meeting,
	Meeting was attended by Attendee;
Directorship began on exactly one appointment-Date;

