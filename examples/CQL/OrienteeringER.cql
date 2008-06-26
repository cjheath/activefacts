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
EventCourse is where
	Course is available at Event,
	Event offers Course;
EventControl is where
	Event includes Control which is worth at most one PointValue;
Event is where
	event-ID may be SeriesEvent and is called EventName and is run by Club using Map on Date at Location;
Map is where
	map Name (as MapName) belongs to Club and has Accessibility;

/*
Constraints:
	REVISIT: Verbalise PresenceConstraint InternalUniquenessConstraint13 min 1 max 1 mandatory over (ID)
	REVISIT: Verbalise PresenceConstraint InternalUniquenessConstraint22 min 0 max 1 over (EventName)
	REVISIT: Verbalise PresenceConstraint InternalUniquenessConstraint4 min 0 max 1 over (SeriesEvent)
	REVISIT: Verbalise PresenceConstraint InternalUniquenessConstraint7 min 0 max 1 over (Name)
	REVISIT: Verbalise PresenceConstraint SimpleMandatoryConstraint21 min 1 mandatory over (Club)
	REVISIT: Verbalise PresenceConstraint SimpleMandatoryConstraint36 min 1 mandatory over (Event)
 */
