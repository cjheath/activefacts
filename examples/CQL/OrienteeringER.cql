vocabulary OrienteeringER;

/*
 * Value Types
 */
Accessibility is written as FixedLengthText;
ClubName is written as VariableLengthText;
Code is written as FixedLengthText;
Control is written as UnsignedInteger(32);
Course is written as FixedLengthText;
Date is written as DateAndTime;
EventName is written as VariableLengthText;
ID is written as AutoCounter;
Location is written as VariableLengthText;
Name is written as VariableLengthText;
Number is written as SignedInteger(32);
PointValue is written as UnsignedInteger(32);
SeriesName is written as VariableLengthText;

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
	event-ID is SeriesEvent called EventName run by Club using Map on Date at Location;
EventControl is where
	Event includes Control which is worth at most one PointValue;
EventCourse is where
	Course is available at Event,
	Event offers Course;
Map is where
	map-Name having Accessibility belongs to Club;

/*
 * Constraints:
 */
each Club occurs at least one time in
	event-ID is SeriesEvent called EventName run by Club using Map on Date at Location;
each Event occurs at least one time in
	Event includes Control which is worth PointValue;
each EventName occurs at most one time in
	event-ID is SeriesEvent called EventName run by Club using Map on Date at Location;
each ID occurs one time in
	event-ID is SeriesEvent called EventName run by Club using Map on Date at Location;
each Name occurs at most one time in
	map-Name having Accessibility belongs to Club;
each SeriesEvent occurs at most one time in
	event-ID is SeriesEvent called EventName run by Club using Map on Date at Location;
