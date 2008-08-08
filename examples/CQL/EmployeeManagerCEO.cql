vocabulary EmployeeManagerCEO;

/*
 * Value Types
 */
PersonName is defined as VariableLengthText();

/*
 * Entity Types
 */
Person is identified by PersonName where
	Person has exactly one PersonName,
	PersonName is of at most one Person;

Employee is a kind of Person;
Employee is manager;

Manager is a kind of Employee;
Employee is managed by at most one Manager [acyclic],
	Manager manages at least one Employee;
Manager is_CEO;

CEO is a kind of Manager;

/*
 * Constraints:
 */
for each Employee exactly one of these holds:
	that Employee is managed by some Manager,
	that Employee is_CEO;
