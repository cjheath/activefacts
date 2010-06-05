vocabulary Address;

/*
 * Value Types
 */
City is written as String(64);
Company Name is written as String;
Family Name is written as String(20);
Given Names is written as String(20);
Number is written as String(12);
Postcode is written as String;
Street Line is written as String(64);

/*
 * Entity Types
 */
Company is identified by its Name;

Family is identified by its Name;

Person is identified by Family and Given Names where
	Person is of one Family,
	Family includes Person,
	Person has one Given Names;

Street is identified by first-Street Line and second-Street Line and third-Street Line where
	Street includes one first-Street Line,
	Street includes at most one second-Street Line,
	Street includes at most one third-Street Line;

Address is identified by street-Number and Street and City and Postcode where
	Address is at at most one street-Number,
	Address is at one Street,
	Address is in one City,
	Address is in at most one Postcode restricted to {1000..9999},
	Postcode is of Address;
Company has head office at at most one Address;
Person lives at at most one Address;

/*
 * Constraints:
 */
Street includes third-Street Line
	only if Street includes second-Street Line;
