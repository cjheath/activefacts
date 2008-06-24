vocabulary EmployeeManagerCEO;

/*
 * Value Types
 */
PersonName is defined as VariableLengthText();

/*
 * Entity Types
 */
Person is identified by PersonName:
	Person has exactly one PersonName,
	PersonName is of at most one Person;
Person is manager;

Employee is a kind of Person;

Manager is a kind of Person;
Employee is managed by at most one Manager [acyclic],
	Manager manages at least one Employee;
Manager is CEO;

CEO is a kind of Manager;

/*
Constraints:
	REVISIT: Verbalise SetExclusionConstraint EmployeeCannotHaveManagerAndBeCEO REVISIT: Unhandled constraint type
 */
