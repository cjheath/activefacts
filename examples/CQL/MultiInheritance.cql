vocabulary MultiInheritance;

/*
 * Value Types
 */
EmployeeID is defined as AutoCounter();
PersonName is defined as VariableLengthText();

/*
 * Entity Types
 */
Person is identified by PersonName where
	Person has exactly one PersonName,
	PersonName is of at most one Person;

Australian is a kind of Person;

Employee is a kind of Person identified by EmployeeID where
	Employee has exactly one EmployeeID,
	EmployeeID is of at most one Employee;

AustralianEmployee is a kind of Australian, Employee;

