vocabulary SimpleMandatory;

/*
 * Value Types
 */
AddressID = AutoCounter();
Address_Id = AutoCounter();
City = VariableLengthText(64);
FamilyName = VariableLengthText(20);
GivenNames = VariableLengthText(20);
Postcode = VariableLengthText();
StreetLine = VariableLengthText(64);
StreetNumber = VariableLengthText(10);

/*
 * Entity Types
 */
Address = entity known by AddressID:
	Address has exactly one AddressID,
	AddressID is of at most one Address;

Family = entity known by FamilyName:
	Family has exactly one FamilyName;

Person = entity known by Family and GivenNames:
	Person has exactly one Family,
	Family is name of Person,
	Person has exactly one GivenNames;

Street = entity known by first-StreetLine and second-StreetLine and third-StreetLine:
	Street includes exactly one first-StreetLine,
	Street includes at most one second-StreetLine,
	Street includes at most one third-StreetLine;

/*
 * Fact Types
 */
Person lives at at most one Address;
Address is at exactly one Street;
Address is in exactly one City;
Address is in at most one Postcode,
	Postcode is of Address;
Address is at at most one StreetNumber;
Family has exactly one FamilyName;

/*
Constraints:
	AddressIsKnownByContents: each combination(AddressIsAtStreetNumber.StreetNumber, AddressIsAtStreet.Street, AddressIsInCity.City, AddressIsInPostcode.Postcode) may occur at most 1 time
	SubsetConstraint SubsetConstraint1 StreetIncludesSecondStreetLine(Street) < StreetIncludesThirdStreetLine(Street)
	SubsetConstraint SubsetConstraint2 StreetIncludesFirstStreetLine(Street) < StreetIncludesSecondStreetLine(Street)
 */
