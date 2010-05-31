vocabulary Death;

/*
 * Value Types
 */
Cause Of Death is written as Variable Length Text;
Person Name is written as Variable Length Text(40);

/*
 * Entity Types
 */
Person is identified by its Name [independent];

Death is where
	Person is dead;
Death was due to at most one Cause Of Death;

