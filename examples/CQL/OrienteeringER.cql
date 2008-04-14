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
Club = entity identified by Code:
	Code is of the club called at most one ClubName,
	the club called ClubName has at most one Code;

Event = entity identified by event-ID:
	event-ID is called EventName and uses Map and is run by Club and is run on Date starting at Location and may be SeriesEvent,
	some event-ID is called some EventName and uses some Map and is run by each Club and is run on some Date starting at some Location and may be some SeriesEvent;

EventControl = entity identified by Event and Control:
	Event includes Control which is worth at most one PointValue,
	each Event includes some Control which is worth some PointValue;

EventCourse = entity identified by Event and Course:
	Course is available at Event,
	Event offers Course;

Map = entity identified by Name:
	map Name belongs to Club and has Accessibility;

SeriesEvent = entity identified by Number and SeriesName:
	SeriesName includes Number,
	event Number is in SeriesName;

/*
Constraints:
	InternalUniquenessConstraint22: in Event, each value (EventName) may occur at most 1 time
	InternalUniquenessConstraint4: in Event, each value (SeriesEvent) may occur at most 1 time
 */
