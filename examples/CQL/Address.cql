vocabulary Address;

/*
 * Value Types
 */
City is written as VariableLengthText(64);
CompanyName is written as VariableLengthText;
FamilyName is written as VariableLengthText(20);
GivenNames is written as VariableLengthText(20);
Number is written as VariableLengthText(12);
Postcode is written as VariableLengthText;
StreetLine is written as VariableLengthText(64);

/*
 * Entity Types
 */
Company is identified by its Name;

Family is identified by its Name;

Person is identified by Family and GivenNames where
	Person is of one Family,
	Family includes Person,
	Person has one GivenNames;

Street is identified by first-StreetLine and second-StreetLine and third-StreetLine where
	Street includes one first-StreetLine,
	Street includes at most one second-StreetLine,
	Street includes at most one third-StreetLine;

Address is identified by street-Number and Street and City and Postcode where
	Address is at at most one street-Number,
	Address is at one Street,
	Address is in one City,
	Address is in at most one Postcode restricted to {1000..9999},
	Postcode restricted to {1000..9999} is of Address;
Company has head office at at most one Address;
Person lives at at most one Address;

/*
 * Constraints:
 */
Street includes third-StreetLine
	only if Street includes second-StreetLine;
