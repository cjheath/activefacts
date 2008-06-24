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
Company is identified by CompanyName:
	Company has exactly one CompanyName,
	CompanyName is of at most one Company;

Family is identified by FamilyName:
	Family has exactly one FamilyName;
Family has FamilyName;

Person is identified by Family and GivenNames:
	Person is of exactly one Family,
	Family includes Person,
	Person has exactly one GivenNames;

Street is identified by first-StreetLine and second-StreetLine and third-StreetLine:
	Street includes exactly one first-StreetLine,
	Street includes at most one second-StreetLine,
	Street includes at most one third-StreetLine;

Address is identified by street-Number and Street and City and Postcode:
	Address is at at most one street-Number,
	Address is at exactly one Street,
	Address is in exactly one City,
	Address is in at most one Postcode,
	Postcode is of Address;
Person lives at at most one Address;
Company has head office at at most one Address;

/*
Constraints:
	REVISIT: Verbalise SubsetConstraint SubsetConstraint1 REVISIT: Unhandled constraint type
	REVISIT: Verbalise SubsetConstraint SubsetConstraint2 REVISIT: Unhandled constraint type
 */
