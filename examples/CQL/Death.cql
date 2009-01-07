vocabulary Death;

/*
 * Value Types
 */
CauseOfDeath is defined as VariableLengthText();
PersonName is defined as VariableLengthText(40);

/*
 * Entity Types
 */
Person is identified by its Name;
Death is where
	Person is dead;
Death was due to at most one CauseOfDeath;

