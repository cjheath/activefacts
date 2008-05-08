vocabulary ObjectifiedUnary;

/*
 * Value Types
 */
CauseOfDeath = VariableLengthText();
PersonName = VariableLengthText(40);

/*
 * Entity Types
 */
Person = entity identified by PersonName:
	Person has exactly one PersonName,
	PersonName is of at most one Person;
