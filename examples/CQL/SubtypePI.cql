vocabulary SubtypePI;

/*
 * Value Types
 */
EntrantID = AutoCounter();
FamilyName = VariableLengthText();
GivenName = VariableLengthText();

/*
 * Entity Types
 */
Entrant = entity identified by EntrantID:
	Entrant has exactly one EntrantID,
	EntrantID is of at most one Entrant;
EntrantHasGivenName = Entrant has at least one GivenName,
	GivenName is of Entrant;

Team = subtype of Entrant;

Competitor = subtype of Entrant;
Competitor has exactly one FamilyName;

/*
Constraints:
	REVISIT: Verbalise SetExclusionConstraint ExclusiveOrConstraint2 REVISIT: Unhandled constraint type
	REVISIT: Verbalise PresenceConstraint FamilyAndGivenNamesAreUnique min 0 max 1 over (FamilyName, GivenName)
 */
