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
Person is manager;

Employee = subtype of Person;

Manager = subtype of Person;
Employee is managed by at most one Manager [acyclic],
	Manager manages at least one Employee,
	each Manager manages some Employee;
Manager is CEO;

CEO = subtype of Manager;

/*
Constraints:
	MandatoryExclusionConstraint EmployeeCannotHaveManagerAndBeCEO over EmployeeIsManagedByManager(Employee), ManagerIsCEO(Manager)
 */
