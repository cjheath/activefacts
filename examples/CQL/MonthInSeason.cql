vocabulary MonthInSeason;

/*
 * Value Types
 */
Event Id is written as Auto Counter;
Month is written as String;
Season is written as String;

/*
 * Entity Types
 */
Event is identified by its Id;

Occurrence is where
	Event occurred in Month;

/*
 * Fact Types
 */
Month is in at most one Season,
	Season contains at least one Month;

