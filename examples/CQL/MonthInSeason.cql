vocabulary MonthInSeason;

/*
 * Value Types
 */
Event Id is written as Auto Counter;
Month is written as Variable Length Text;
Season is written as Variable Length Text;

/*
 * Entity Types
 */
Event is identified by its Id;

Occurrence is where
	Event occurred in Month;

/*
 * Fact Types
 */
Month is in at most one Season;

/*
 * Constraints:
 */
each Season occurs at least one time in
	Month is in Season;
