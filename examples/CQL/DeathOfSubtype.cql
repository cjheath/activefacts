vocabulary DeathOfSubtype;

/*
 * Value Types
 */
CauseOfDeath is defined as VariableLengthText();
Party_Id is defined as AutoCounter();

/*
 * Entity Types
 */
Party is identified by Party_Id where
	Party has exactly one Party_Id,
	Party_Id is of at most one Party;

Person is a kind of Party;
Death is where
	Person is dead;
Death was caused by at most one CauseOfDeath;

