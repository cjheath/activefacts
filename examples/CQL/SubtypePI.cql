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
	each Entrant has some GivenName,
	GivenName is of Entrant;

Team = subtype of Entrant;

Competitor = subtype of Entrant;
Competitor has exactly one FamilyName;

/*
Constraints:
	MandatoryExclusionConstraint ExclusiveOrConstraint2 over CompetitorIsASubtypeOfEntrant(Entrant), TeamIsASubtypeOfEntrant(Entrant)
	FamilyAndGivenNamesAreUnique: each combination(CompetitorHasFamilyName.FamilyName, EntrantHasGivenName.GivenName) may occur at most 1 time
 */
