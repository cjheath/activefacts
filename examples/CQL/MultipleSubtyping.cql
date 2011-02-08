vocabulary MultipleSubtyping;

/*
 * Value Types
 */
Person Name is written as String;

/*
 * Entity Types
 */
Person is identified by its Name;

Teenager is a kind of Person;

Adult is a kind of Person;

Child is a kind of Person;

Female is a kind of Person;

Male is a kind of Person;

/*
 * Constraints:
 */
for each Person exactly one of these holds:
	Person is a Child,
	Person is a Teenager,
	Person is an Adult;
either Person is a Male or Person is a Female but not both;
