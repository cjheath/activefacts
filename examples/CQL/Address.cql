vocabulary Address;

/*
 * Value Types
 */
City = VariableLengthText(64);
CompanyName = VariableLengthText();
FamilyName = VariableLengthText(20);
GivenNames = VariableLengthText(20);
Number = VariableLengthText(12);
Postcode = VariableLengthText();
StreetLine = VariableLengthText(64);

/*
 * Entity Types
 */
Company = entity identified by CompanyName:
	Company has exactly one CompanyName,
	CompanyName is of at most one Company;

Family = entity identified by FamilyName:
	Family has exactly one FamilyName;
Family has FamilyName;

Person = entity identified by Family and GivenNames:
	Person is of exactly one Family,
	Family includes Person,
	Person has exactly one GivenNames;

Street = entity identified by first-StreetLine and second-StreetLine and third-StreetLine:
	Street includes exactly one first-StreetLine,
	Street includes at most one second-StreetLine,
	Street includes at most one third-StreetLine;

Address = entity identified by street-Number and Street and City and Postcode:
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
