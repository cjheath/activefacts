vocabulary ObjectifiedUnary;

/*
 * Value Types
 */
CauseOfDeath is defined as VariableLengthText();
PersonName is defined as VariableLengthText(40);

/*
 * Entity Types
 */
Person is identified by PersonName where
	Person has exactly one PersonName,
	PersonName is of at most one Person;
