vocabulary MultiInheritance;

/*
 * Value Types
 */
Employee ID is written as Auto Counter;
Person Name is written as String;
TFN is written as Char(9);

/*
 * Entity Types
 */
Person is identified by its Name;

Australian is a kind of Person;
Australian has at most one TFN,
	TFN is of one Australian;

Employee is a kind of Person identified by its ID;

Australian Employee is a kind of Employee, Australian;

