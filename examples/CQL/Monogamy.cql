vocabulary Monogamy;

/*
 * Value Types
 */
Name is written as VariableLengthText;
PersonID is written as AutoCounter;

/*
 * Entity Types
 */
Person is identified by its ID;
Person is called one Name;

Boy is a kind of Person;

Girl is a kind of Person;
Girl (as Girlfriend) is going out with at most one Boy (as Boyfriend) [symmetric],
	Boyfriend is going out with at most one Girlfriend;

/*
 * Constraints:
 */
for each Person exactly one of these holds:
	Girl is a subtype of Person,
	Boy is a subtype of Person;
