vocabulary CompanyDirectorName2;

/*
 * Value Types
 */
CompanyName = VariableLengthText();
Date = Date();
Name = VariableLengthText(48);

/*
 * Entity Types
 */
Company = entity known by CompanyName:
	Company is called exactly one CompanyName,
	CompanyName is of at most one Company;

Meeting = entity known by Date and Company:
	Meeting is held on exactly one Date,
	Meeting is of exactly one Company;
Meeting is board meeting;

Person = entity known by family-Name and given-Name:
	Person has exactly one family-Name,
	family-Name is of Person,
	Person has exactly one given-Name,
	given-Name is of Person;
Attendance = Person attended Meeting,
	Meeting was attended by Person;
Person was born on at most one birth-Date;

Directorship = entity known by Company and Person:
	Person directs Company,
	Company is directed by at least one Person,
	each Company is directed by some Person;
Directorship began on exactly one appointment-Date;

