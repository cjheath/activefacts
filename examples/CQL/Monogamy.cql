vocabulary Monogamy;

/*
 * Value Types
 */
Name is written as String;
Person ID is written as Auto Counter;

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
either Person is a Girl or Person is a Boy but not both;
