vocabulary CompanyDirectorEmployee;

/*
 * Value Types
 */
Company Name is written as String(48);
Date is written as Date;
Employee Nr is written as Signed Integer(32);
Name is written as String(48);

/*
 * Entity Types
 */
Company is identified by its Name where
	Company is called Company Name;
Company is listed;

Employee is identified by its Nr;
Employee works at one Company,
	Company employs Employee;

Manager is a kind of Employee;
Employee is supervised by at most one Manager [acyclic],
	Manager supervises Employee;
Manager is ceo;

Meeting is independent identified by Company and Date and Meeting is board meeting where
	Meeting is held by one Company,
	Company held Meeting,
	Meeting is held on one Date,
	Meeting is board meeting;

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

Employment is where
	Person works as Employee,
	Employee role is assigned to at least one Person;

/*
 * Constraints:
 */
either Employee is supervised by Manager(1) or Employee is a Manager(2) that is ceo but not both;
