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
 * Fact Types
 */
Club = Code is of the club called at most one ClubName,
	the club called ClubName has at most one Code;
SeriesEvent = SeriesName includes event-Number,
	event Number is in SeriesName;
EventCourse = Course is available at Event,
	Event offers Course;
EventControl = Event includes Control which is worth at most one PointValue;
