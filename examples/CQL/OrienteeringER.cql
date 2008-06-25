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
EventControl is where
	Event includes Control which is worth at most one PointValue;
EventCourse is where
	Course is available at Event,
	Event offers Course;
SeriesEvent is where
	SeriesName includes event-Number,
	event Number is in SeriesName;

