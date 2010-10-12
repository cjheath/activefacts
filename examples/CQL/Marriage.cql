vocabulary Marriage;

/*
 * Value Types
 */
Name is written as String;

/*
 * Entity Types
 */
Person is independent identified by given-Name and family-Name where
	Person has one given-Name,
	Person has one family-Name;

Marriage is identified by Husband and Wife where
	Marriage is by one husband-Person (as Husband),
	Marriage is of one wife-Person (as Wife);

