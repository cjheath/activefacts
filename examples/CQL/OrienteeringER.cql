vocabulary OrienteeringER;

/*
 * Value Types
 */
Accessibility is defined as FixedLengthText();
ClubName is defined as VariableLengthText();
Code is defined as FixedLengthText();
Control is defined as UnsignedInteger(32);
Course is defined as FixedLengthText();
Date is defined as DateAndTime();
EventName is defined as VariableLengthText();
ID is defined as AutoCounter();
Location is defined as VariableLengthText();
Name is defined as VariableLengthText();
Number is defined as SignedInteger(32);
PointValue is defined as UnsignedInteger(32);
SeriesName is defined as VariableLengthText();

/*
 * Fact Types
 */
Club is where
	Code is of the club called at most one ClubName,
	the club called ClubName has at most one Code;
SeriesEvent is where
	SeriesName includes event-Number,
	event Number is in SeriesName;
Event is where
	event-ID may be SeriesEvent and is called EventName and is run by Club using Map on Date at Location;
EventControl is where
	Event includes Control which is worth at most one PointValue;
EventCourse is where
	Course is available at Event,
	Event offers Course;
Map is where
	map Name (as MapName) belongs to Club and has Accessibility;

/*
Constraints:
	REVISIT: each (ID) occurs exactly one time in 'event-ID may be SeriesEvent and is called EventName and is run by Club using Map on Date at Location'
	REVISIT: each (EventName) occurs at most one time in 'event-ID may be SeriesEvent and is called EventName and is run by Club using Map on Date at Location'
	REVISIT: each (SeriesEvent) occurs at most one time in 'event-ID may be SeriesEvent and is called EventName and is run by Club using Map on Date at Location'
	REVISIT: each (Name) occurs at most one time in 'map MapName belongs to Club and has Accessibility'
	REVISIT: each (Club) occurs at least one time in 'event-ID may be SeriesEvent and is called EventName and is run by Club using Map on Date at Location'
	REVISIT: each (Event) occurs at least one time in 'Event includes Control which is worth PointValue'
 */
