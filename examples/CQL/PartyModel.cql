vocabulary Party;

/*
 * Value Types
 */
Party ID is written as ID;
Party Type Code is written as String(16) restricted to {'Company', 'Person'};

/*
 * Entity Types
 */
Party is identified by its ID;

Party Type is identified by its Code;
Party is of one Party Type;

Person is a kind of Party [separate];

User is a kind of Person;

Company is a kind of Party [separate];

Superannuation Company is a kind of Company;

Teaching Institution is a kind of Company;

RTO is a kind of Teaching Institution;

/*
 * Constraints:
 */
either Party is a Person or Party is a Company but not both;
Party is a Company
	if and only if
	Party is of Party Type 'Company';
Party is a Person
	if and only if
	Party is of Party Type 'Person';
