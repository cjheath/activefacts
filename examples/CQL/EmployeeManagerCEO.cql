vocabulary SubType;

/*
 * Value Types
 */
PersonName = VariableLengthText();

/*
 * Entity Types
 */
Person = entity known by PersonName:
	Person has exactly one PersonName,
	PersonName is of at most one Person;

Employee = subtype of Person;

Manager = subtype of Person;

CEO = subtype of Manager;

/*
 * Fact Types
 */
Employee is managed by at most one Manager [acyclic],
	Manager manages at least 1 Employee;
Manager is CEO;
Person is manager;

/*
Constraints:
	MandatoryExclusionConstraint EmployeeCannotHaveManagerAndBeCEO over EmployeeIsManagedByManager(Employee), ManagerIsCEO(Manager)
 */
