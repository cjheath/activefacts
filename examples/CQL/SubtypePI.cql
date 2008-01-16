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
Entrant = entity known by EntrantID:
	Entrant has exactly one EntrantID,
	EntrantID is of at most one Entrant;

Team = subtype of Entrant;

Competitor = subtype of Entrant;

/*
 * Fact Types
 */
EntrantHasGivenName = Entrant has GivenName,
	GivenName is of Entrant;
Competitor has exactly one FamilyName;

/*
Constraints:
	FamilyAndGivenNamesAreUnique: each combination(CompetitorHasFamilyName.FamilyName, EntrantHasGivenName.GivenName) may occur at most 1 time
	ExclusionConstraint ExclusiveOrConstraint2 over CompetitorIsASubtypeOfEntrant(Entrant), TeamIsASubtypeOfEntrant(Entrant)
 */
