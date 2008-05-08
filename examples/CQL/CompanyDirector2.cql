vocabulary CompanyDirector;

/*
 * Value Types
 */
CompanyName = VariableLengthText();
Date = Date();
Name = VariableLengthText(48);

/*
 * Entity Types
 */
Company = entity identified by CompanyName:
	Company is called exactly one CompanyName,
	CompanyName is of at most one Company;

Meeting = entity identified by Date and Company:
	Meeting is held on exactly one Date,
	Meeting is of exactly one Company;
Meeting is board meeting;

Person = entity identified by family-Name and given-Name:
	Person has at most one family-Name,
	family-Name is of Person,
	Person has exactly one given-Name,
	given-Name is of Person;
Directorship = Person (as director) directs Company,
	Company is directed by at least one director;
Attendance = Person (as Attendee) attended Meeting,
	Meeting was attended by Attendee;
Person was born on at most one birth-Date;
Directorship began on exactly one appointment-Date;

