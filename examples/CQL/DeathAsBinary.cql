vocabulary DeathAsBinary;

/*
 * Value Types
 */
CauseOfDeath is defined as VariableLengthText();
Person_Name is defined as VariableLengthText();

/*
 * Entity Types
 */
Person is identified by its _Name;

Death is identified by Person where
	Person suffered at most one Death;
Death was caused by at most one CauseOfDeath;

/*
 * Constraints:
 */
each Death occurs exactly one time in
	Person suffered Death;
