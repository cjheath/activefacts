vocabulary EmployeeManagerCEO;

/*
 * Value Types
 */
PersonName = VariableLengthText();

/*
 * Entity Types
 */
Person = entity identified by PersonName:
	Person has exactly one PersonName,
	PersonName is of at most one Person;
Person is manager;

Employee = subtype of Person;

Manager = subtype of Person;
Employee is managed by at most one Manager [acyclic],
	Manager manages at least one Employee;
Manager is CEO;

CEO = subtype of Manager;

/*
Constraints:
	REVISIT: Verbalise SetExclusionConstraint EmployeeCannotHaveManagerAndBeCEO REVISIT: Unhandled constraint type
 */
