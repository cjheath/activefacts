vocabulary CompanyDirector;

/*
 * Value Types
 */
CompanyName = VariableLengthText(48);
Date = Date();
PersonName = VariableLengthText(48);

/*
 * Entity Types
 */
Company = entity known by CompanyName:
	Company has exactly one CompanyName,
	CompanyName is of at most one Company;

Person = entity known by PersonName:
	Person has exactly one PersonName,
	PersonName is of at most one Person;

Directorship = entity known by Person and Company:
	Person directs Company,
	Company is directed by Person;

/*
 * Fact Types
 */
Directorship began on exactly one appointment-Date;
Attendance = Person attended board meeting of Company on Date,
	Person attended on Date a board meeting for Company;
Person was born on at most one birth-Date;
