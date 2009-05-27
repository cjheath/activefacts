vocabulary MonthInSeason;

/*
 * Value Types
 */
EventId is written as AutoCounter;
Month is written as VariableLengthText;
Season is written as VariableLengthText;

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
