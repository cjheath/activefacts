vocabulary Address;

/*
 * Value Types
 */
City is defined as VariableLengthText(64);
CompanyName is defined as VariableLengthText();
FamilyName is defined as VariableLengthText(20);
GivenNames is defined as VariableLengthText(20);
Number is defined as VariableLengthText(12);
Postcode is defined as VariableLengthText();
StreetLine is defined as VariableLengthText(64);

/*
 * Entity Types
 */
Company is identified by its Name;

Family is identified by its Name;

Person is identified by Family and GivenNames where
	Person is of exactly one Family,
	Family includes Person,
	Person has exactly one GivenNames;

Street is identified by first-StreetLine and second-StreetLine and third-StreetLine where
	Street includes exactly one first-StreetLine,
	Street includes at most one second-StreetLine,
	Street includes at most one third-StreetLine;

Address is identified by street-Number and Street and City and Postcode where
	Address is at at most one street-Number,
	Address is at exactly one Street,
	Address is in exactly one City,
	Address is in at most one Postcode,
	Postcode is of Address;
Company has head office at at most one Address;
Person lives at at most one Address;

/*
 * Constraints:
 */
Street includes third-StreetLine
	only if Street includes second-StreetLine;
Street includes second-StreetLine
	only if Street includes first-StreetLine;
