vocabulary Marriage;

/*
 * Value Types
 */
Name is defined as VariableLengthText();

/*
 * Entity Types
 */
Person is identified by given-Name and family-Name where
	Person has exactly one given-Name,
	Person has exactly one family-Name;

Marriage is identified by Husband and Wife where
	Marriage is by exactly one husband-Person (as Husband),
	Marriage is of exactly one wife-Person (as Wife);

