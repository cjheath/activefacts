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
Company = entity identified by CompanyName:
	Company is called exactly one CompanyName,
	CompanyName is of at most one Company;

Person = entity identified by PersonName:
	Person has exactly one PersonName,
	PersonName is of at most one Person;
Directorship = Person (as Director) directs Company,
	Company is directed by at least one Director;
Attendance = Person attended board meeting of Company on Date,
	Person attended on Date a board meeting for Company;
Person was born on at most one birth-Date;
Directorship began on exactly one appointment-Date;

