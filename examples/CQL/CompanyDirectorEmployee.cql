vocabulary CompanyDirectorEmployee;

/*
 * Value Types
 */
CompanyName is written as VariableLengthText(48);
EmployeeNr is written as SignedInteger(32);
Name is written as VariableLengthText(48);

/*
 * Entity Types
 */
Company is identified by its Name where
	Company is called CompanyName;
Company is listed;

Meeting is identified by Date and Meeting is board meeting and Company where
	Meeting is held on one Date,
	Meeting is board meeting,
	Company held Meeting,
	Meeting is held by one Company;

Person is identified by given-Name and family-Name where
	Person has one given-Name,
	given-Name is of Person,
	family-Name is of Person,
	Person is called at most one family-Name;
Person was born on at most one birth-Date restricted to {'1900/01/01'..};
Attendance is where
	Person (as Attendee) attended Meeting,
	Meeting was attended by Attendee;
Directorship is where
	Person (as Director) directs Company,
	Company is directed by at least one Director;
Directorship began on one appointment-Date;

Employee is a kind of Person identified by its Nr;
Employee works at one Company,
	Company employs Employee;

Manager is a kind of Employee;
Employee is supervised by at most one Manager [acyclic],
	Manager supervises Employee;
Manager is ceo;

/*
 * Constraints:
 */
for each Employee exactly one of these holds:
	that Employee is ceo,
	that Employee is supervised by some Manager;
