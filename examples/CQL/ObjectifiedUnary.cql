vocabulary ObjectifiedUnary;

/*
 * Value Types
 */
CauseOfDeath = VariableLengthText();
PersonName = VariableLengthText(40);

/*
 * Entity Types
 */
Person = entity known by PersonName:
	Person has exactly one PersonName,
	PersonName is of at most one Person;

Death = entity known by Person:
	Person is dead;
Death was due to at most one CauseOfDeath;

