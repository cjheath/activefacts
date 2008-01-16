vocabulary PersonName;

/*
 * Value Types
 */
GivenNames = VariableLengthText(64);
Name = VariableLengthText(32);
Ordinal = UnsignedSmallInteger(32);
PersonId = AutoCounter();

/*
 * Entity Types
 */
Person = entity known by PersonId:
	Person has exactly one PersonId,
	PersonId is of at most one Person;

/*
 * Fact Types
 */
Person has exactly one family-Name;
PersonHasOrdinalGivenName = Person has Ordinal at most one given-Name,
	Person has given-Name as Ordinal name;
Person is called at most one GivenNames;
