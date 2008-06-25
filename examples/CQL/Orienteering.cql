vocabulary Orienteering;

/*
 * Value Types
 */
Accessibility is defined as FixedLengthText(1) restricted to {'A'..'D'};
ClubCode is defined as VariableLengthText(6);
ClubName is defined as VariableLengthText(32);
ControlNumber is defined as UnsignedInteger(32) restricted to {1..1000};
Course is defined as VariableLengthText(16) restricted to {'A'..'E', 'PW'};
EntryID is defined as AutoCounter();
EventID is defined as AutoCounter();
EventName is defined as VariableLengthText(50);
FamilyName is defined as VariableLengthText(48);
Gender is defined as FixedLengthText(1) restricted to {'M', 'F'};
GivenName is defined as VariableLengthText(48);
Location is defined as VariableLengthText(200);
MapID is defined as AutoCounter();
MapName is defined as VariableLengthText(80);
Number is defined as UnsignedInteger(32) restricted to {1..100};
PersonID is defined as AutoCounter();
Placing is defined as UnsignedInteger(32);
PointValue is defined as UnsignedInteger(32);
PostCode is defined as UnsignedInteger(32);
PunchID is defined as AutoCounter();
Score is defined as SignedInteger(32);
ScoringMethod is defined as VariableLengthText(32) restricted to {'Score', 'Scatter', 'Special'};
SeriesID is defined as AutoCounter();
SeriesName is defined as VariableLengthText(40);
StartTime is defined as DateAndTime();
Time is defined as DateAndTime();
Year is defined as UnsignedInteger(32) restricted to {1900..3000};

/*
 * Entity Types
 */
Club is identified by ClubCode:
	Club has exactly one ClubCode,
	ClubCode is of at most one Club;
ClubName is name of at most one Club,
	Club is called exactly one ClubName;

Event is identified by EventID:
	Event has exactly one EventID,
	EventID is of at most one Event;
Event is called at most one EventName,
	EventName is name of at most one Event;
Event starts at exactly one start-Location,
	Location is where Event starts;
Event is held on exactly one StartTime;
EventScoringMethod is where
	ScoringMethod is used for Course of Event;
Event has at most one Number;
Club runs Event,
	Event is run by exactly one Club;
EventControl is where
	Event includes at least one ControlNumber;
EventControl has at most one PointValue;

Map is identified by MapID:
	Map has exactly one MapID,
	MapID is of at most one Map;
Map is map for Event,
	Event uses exactly one Map;
Map has exactly one MapName,
	MapName is of at most one Map;
Club (as Owner) owns Map,
	Map is owned by exactly one Owner;
Map has at most one Accessibility;

Person is identified by PersonID:
	Person has exactly one PersonID,
	PersonID is of at most one Person;
Person has exactly one FamilyName,
	FamilyName is of Person;
Person has exactly one GivenName,
	GivenName is name of Person;
Person is of at most one Gender;
Person was born in at most one birth-Year;
Person has at most one PostCode;
Person is member of at most one Club;
Entry is identified by EntryID:
	Entry has exactly one EntryID,
	EntryID is of at most one Entry;
Entry received at most one Score;
Entry finished in at most one finish-Placing;

Punch is identified by PunchID:
	Punch has exactly one PunchID,
	PunchID is of at most one Punch;
Visit is where
	Punch was visited by Entry at Time;
PunchPlacement is where
	Punch is placed at EventControl;

Series is identified by SeriesID:
	Series has exactly one SeriesID,
	SeriesID is of at most one Series;
Series has exactly one SeriesName (as Name),
	Name is of at most one Series;
Event is in at most one Series;

/*
Constraints:
	REVISIT: Verbalise PresenceConstraint CompetitorHasDistinctName min 0 max 1 over (GivenName, FamilyName)
	REVISIT: Verbalise SetEqualityConstraint EqualityConstraint1 REVISIT: Unhandled constraint type
	REVISIT: Verbalise PresenceConstraint EventHasSeriesNumberOrName min 1 mandatory over (Event, Event)
	REVISIT: Verbalise PresenceConstraint ExternalUniquenessConstraint1 min 0 max 1 over (Series, Number)
	REVISIT: Verbalise PresenceConstraint OnlyOneScoringMethodForEachEventAndCourse min 0 max 1 over (Course, Event)
	REVISIT: Verbalise PresenceConstraint PersonMayEnterEventOnce min 0 max 1 over (Person, Event)
	REVISIT: Verbalise PresenceConstraint SimpleMandatoryConstraint28 min 1 mandatory over (EventControl)
 */
