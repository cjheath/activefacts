vocabulary Supervision;

/*
 * Value Types
 */
CompanyName is written as String;
EmployeeNr is written as Signed Integer(32);

/*
 * Entity Types
 */
Company is identified by its Name;

Employee is identified by Company and EmployeeNr where
	Employee works for one Company,
	Company employs Employee,
	Employee has one EmployeeNr,
	EmployeeNr is of Employee;

Manager is a kind of Employee;
Manager supervises Employee,
	Employee reports to at most one Manager;

CEO is a kind of Manager;
CEO runs Company,
	Company is run by one CEO;

/*
 * Constraints:
 */
either Employee reports to Manager(1) or Employee is a Manager(2) that is a CEO that runs Company but not both;
Employee is a Manager that is a CEO that runs Company
	if and only if
	Employee works for Company;
