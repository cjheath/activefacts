vocabulary Death;

/*
 * Value Types
 */
Cause Of Death is written as String;
Person Name is written as String(40);

/*
 * Entity Types
 */
Person is identified by its Name [independent];

Death is where
	Person is dead;
Death was due to at most one Cause Of Death;

