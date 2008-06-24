vocabulary CompanyDirector;

/*
 * Value Types
 */
CompanyName is defined as VariableLengthText();
Date is defined as Date();
Name is defined as VariableLengthText(48);

/*
 * Entity Types
 */
Company is identified by CompanyName:
	Company is called exactly one CompanyName,
	CompanyName is of at most one Company;

Meeting is identified by Date and Company:
	Meeting is held on exactly one Date,
	Meeting is of exactly one Company;
Meeting is board meeting;

Person is identified by family-Name and given-Name:
	Person has at most one family-Name,
	family-Name is of Person,
	Person has exactly one given-Name,
	given-Name is of Person;
Directorship is where
	Person (as director) directs Company,
	Company is directed by at least one director;
Attendance is where
	Person (as Attendee) attended Meeting,
	Meeting was attended by Attendee;
Person was born on at most one birth-Date;
Directorship began on exactly one appointment-Date;

