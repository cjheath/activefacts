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
 */

where	Address is at StreetNumber,
	Address is at Street,
	Address is in City,
	Address is in Postcode
require that the combination(StreetNumber, Street, City, Postcode) is unique;

where	Street includes second-StreetLine,
	Street includes third-StreetLine
require that the set third-StreetLine is a subset of second-StreetLine;

SubsetConstraint options:
1)
Street in Street includes second-StreetLine
is a subset of
Street in Street includes third-StreetLine;

the combination(
    ...
    ...
)
is a subset of
the combination(
    ...
    ...
);

2) if A then B:
    if "some Street includes some third-StreetLine"
    then "that Street includes some second-StreetLine";

2a)
    for some A and some B
	if ..... that A..... that B.... some C"
	then ..... that A..... that B.... some C"

2b)
    if some A.... some B....some C
    then that A.... that B.... some D

3)
    B only if A;

    "some Street includes some second-StreetLine"
    only if
    "that Street includes some first-StreetLine";

3a)
    for some A and some B
	.... that A..... that B.... some C
    only if
	.... that A..... that B..... some D;

3b)
    for some A and some B
    if .... that A..... that B..... some D
    then .... that A..... that B.... some C;

EqualityConstraint:

1)
if and only if
    A
    then B;

for some A and some B
    if and only if
    .... that A..... that B..... some C
    then ..... that A..... that B..... some C;

2)
B if and only if A;

for some A and some B
    ..... that A..... that B..... some C
    if and only if
    .... that A..... that B..... some C;

ExclusionConstraint:

1)
if and only if
    A
    then B;

for some A and some B
    if and only if
    .... that A..... that B..... some C
    then ..... that A..... that B..... some C;

2)
for some A
    at most one of the following holds:
    ... that A..... some B
    or
    ... that A..... some C
    ;

for some A
    maybe ... that A..... some B
    unless ... that A..... some C
    or... (doesn't work for more than two alternatives)
    ;

3)
for some A and some B
    maybe ..... that A..... that B..... some C
    unless
    .... that A..... that B..... some C;
