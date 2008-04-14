vocabulary PersonAddress;

/*
 * Value Types
 */
Address_Id = AutoCounter();
City = VariableLengthText(64);
FamilyName = VariableLengthText(20);
GivenNames = VariableLengthText(20);
Postcode = VariableLengthText();
StreetLine = VariableLengthText(64);
StreetNumber = VariableLengthText(12);

/*
 * Entity Types
 */
Family = entity identified by FamilyName:
	Family has exactly one FamilyName;
Family has FamilyName;

Person = entity identified by Family and GivenNames:
	Person has exactly one Family,
	Family is name of Person,
	Person has exactly one GivenNames;

Street = entity identified by first-StreetLine and second-StreetLine and third-StreetLine:
	Street includes exactly one first-StreetLine,
	Street includes at most one second-StreetLine,
	Street includes at most one third-StreetLine;

Address = entity identified by StreetNumber and Street and City and Postcode:
	Address is at at most one StreetNumber,
	Address is at exactly one Street,
	Address is in exactly one City,
	Address is in at most one Postcode,
	Postcode is of Address;
Person lives at at most one Address;

/*
Constraints:
	SubsetConstraint SubsetConstraint1 StreetIncludesSecondStreetLine(Street) < StreetIncludesThirdStreetLine(Street)
	SubsetConstraint SubsetConstraint2 StreetIncludesFirstStreetLine(Street) < StreetIncludesSecondStreetLine(Street)
 */
