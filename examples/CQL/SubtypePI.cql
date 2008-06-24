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
Entrant is identified by EntrantID:
	Entrant has exactly one EntrantID,
	EntrantID is of at most one Entrant;
EntrantHasGivenName is where
	Entrant has at least one GivenName,
	GivenName is of Entrant;

Team is a kind of Entrant identified by TeamID:
	Team has exactly one TeamID,
	TeamID is of at most one Team;

Competitor is a kind of Entrant;
Competitor has exactly one FamilyName;

/*
Constraints:
	REVISIT: Verbalise SetExclusionConstraint ExclusiveOrConstraint2 REVISIT: Unhandled constraint type
	REVISIT: Verbalise PresenceConstraint FamilyAndGivenNamesAreUnique min 0 max 1 over (FamilyName, GivenName)
 */
