vocabulary DeathAsBinary;

/*
 * Value Types
 */
CauseOfDeath is defined as VariableLengthText();
PersonName is defined as VariableLengthText();

/*
 * Entity Types
 */
Person is identified by its Name;

Death is identified by Person where
	Person suffered at most one Death;
Death was caused by at most one CauseOfDeath;

/*
 * Constraints:
 */
each Death occurs exactly one time in
	Person suffered Death;
