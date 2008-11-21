vocabulary MultiInheritance;

/*
 * Value Types
 */
EmployeeID is defined as AutoCounter();
PersonName is defined as VariableLengthText();

/*
 * Entity Types
 */
Person is identified by its Name;

Australian is a kind of Person;

Employee is a kind of Person identified by its ID;

AustralianEmployee is a kind of Employee, Australian;

