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
Constraints:
	REVISIT: mandatory exclusion over (Entrant) in 'Competitor is a kind of Entrant', (Entrant) in 'Team is a kind of Entrant'
	REVISIT: at most one UNKNOWN exists for each 'Competitor has FamilyName', 'Entrant has GivenName'
 */
