vocabulary SubtypePI;

/*
 * Value Types
 */
EntrantID is defined as AutoCounter();
FamilyName is defined as VariableLengthText();
GivenName is defined as VariableLengthText();
TeamID is defined as AutoCounter();

/*
 * Entity Types
 */
Entrant is identified by EntrantID where
	Entrant has exactly one EntrantID,
	EntrantID is of at most one Entrant;
EntrantHasGivenName is where
	Entrant has at least one GivenName,
	GivenName is of Entrant;

Team is a kind of Entrant identified by TeamID where
	Team has exactly one TeamID,
	TeamID is of at most one Team;

Competitor is a kind of Entrant;
Competitor has exactly one FamilyName;

/*
 * Constraints:
for each Entrant exactly one of these holds:
	Competitor is a subtype of Entrant,
	Team is a subtype of Entrant;
 */
each combination FamilyName, GivenName occurs at most one time in
	Competitor has FamilyName,
	Entrant has GivenName;
