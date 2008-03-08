vocabulary CompanyDirectorName;

/*
 * Value Types
 */
CompanyName = VariableLengthText(48);
Date = Date();
Name = VariableLengthText(48);

/*
 * Entity Types
 */
Company = entity known by CompanyName:
	Company is called exactly one CompanyName,
	CompanyName is of at most one Company;

Meeting = entity known by Date and Company:
	Company held meeting on Date;
Meeting is board meeting;

Person = entity known by given-Name and family-Name:
	Person has exactly one given-Name,
	given-Name is of Person,
	family-Name is of Person,
	Person is called at most one family-Name;
Person was born on at most one birth-Date;
Attendance = Person attended Meeting,
	Meeting was attended by Person;

Directorship = entity known by Person and Company:
	Person directs Company,
	Company is directed by at least one Person,
	each Company is directed by some Person;
Directorship began on exactly one appointment-Date;

