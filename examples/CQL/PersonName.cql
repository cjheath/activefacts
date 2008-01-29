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
Person has exactly one family-Name;
PersonHasGivenNameAsOrdinalName = Person has at most one given-Name as Ordinal name,
	Person has Ordinal given-Name;
Person is called at most one GivenNames;

