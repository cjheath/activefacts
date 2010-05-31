vocabulary SubtypePI;

/*
 * Value Types
 */
Entrant ID is written as Auto Counter;
Family Name is written as Variable Length Text;
Given Name is written as Variable Length Text;
Team ID is written as Auto Counter;

/*
 * Entity Types
 */
Entrant is identified by its ID;

Entrant Given Name is where
	Entrant has at least one Given Name,
	Given Name is of Entrant;

Team is a kind of Entrant identified by its ID;

Competitor is a kind of Entrant;
Competitor has one Family Name;

/*
 * Constraints:
 */
either Entrant is a Competitor or Entrant is a Team but not both;
each combination Family Name, Given Name occurs at most one time in
	Competitor has Family Name,
	Entrant has Given Name;
