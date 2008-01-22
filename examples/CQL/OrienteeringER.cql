vocabulary OrienteeringER;

/*
 * Value Types
 */
Accessibility = FixedLengthText();
ClubName = VariableLengthText();
Code = FixedLengthText();
Control = UnsignedInteger(32);
Course = FixedLengthText();
Date = DateAndTime();
EventName = VariableLengthText();
ID = AutoCounter();
Location = VariableLengthText();
Name = VariableLengthText();
Number = SignedInteger(32);
PointValue = UnsignedInteger(32);
SeriesName = VariableLengthText();

/*
 * Entity Types
 */
Club = entity known by Code:
	Code is of the club called at most one ClubName,
	the club called ClubName has at most one Code;

Event = entity known by ID:
	event ID is called EventName and uses Map and is run by Club and is run on Date starting at Location and may be SeriesEvent;

EventControl = entity known by Event and Control:
	Event includes Control which is worth at most one PointValue;

EventCourse = entity known by Event and Course:
	Course is available at Event,
	Event offers Course;

Map = entity known by Name:
	map Name belongs to Club and has Accessibility;

SeriesEvent = entity known by Number and SeriesName:
	SeriesName includes Number,
	event Number is in SeriesName;

/*
 * Fact Types
 */

/*
Constraints:
	InternalUniquenessConstraint22: in Event, each value (EventName) may occur at most 1 time
	InternalUniquenessConstraint4: in Event, each value (SeriesEvent) may occur at most 1 time
	SimpleMandatoryConstraint21: in Event, each value (Club) must occur at least 1 time
	SimpleMandatoryConstraint36: in EventControl, each value (Event) must occur at least 1 time
	SimpleMandatoryConstraint22: in Event, each value (Map) must occur at least 1 time
	SimpleMandatoryConstraint20: in Event, each value (Date) must occur at least 1 time
	SimpleMandatoryConstraint19: in Event, each value (Location) must occur at least 1 time
	SimpleMandatoryConstraint37: in EventControl, each value (Control) must occur at least 1 time
 */
