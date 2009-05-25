vocabulary SubtypePI;

/*
 * Value Types
 */
EntrantID is written as AutoCounter;
FamilyName is written as VariableLengthText;
GivenName is written as VariableLengthText;
TeamID is written as AutoCounter;

/*
 * Entity Types
 */
Entrant is identified by its ID;
EntrantHasGivenName is where
	Entrant has at least one GivenName,
	GivenName is of Entrant;

Team is a kind of Entrant identified by its ID;

Competitor is a kind of Entrant;
Competitor has one FamilyName;

/*
 * Constraints:
 */
for each Entrant exactly one of these holds:
	Competitor is a subtype of Entrant,
	Team is a subtype of Entrant;
each combination FamilyName, GivenName occurs at most one time in
	Competitor has FamilyName,
	Entrant has GivenName;
