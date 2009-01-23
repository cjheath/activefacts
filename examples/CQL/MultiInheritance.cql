vocabulary MultiInheritance;

/*
 * Value Types
 */
EmployeeID is defined as AutoCounter();
PersonName is defined as VariableLengthText();
TFN is defined as FixedLengthText(9);

/*
 * Entity Types
 */
Person is identified by its Name;

Australian is a kind of Person;
Australian has at most one TFN,
	TFN is of one Australian;

Employee is a kind of Person identified by its ID;

AustralianEmployee is a kind of Employee, Australian;

