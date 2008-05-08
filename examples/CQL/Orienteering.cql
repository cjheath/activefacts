vocabulary Orienteering;

/*
 * Value Types
 */
Accessibility = FixedLengthText(1) restricted to {'A'..'D'};
ClubCode = VariableLengthText(6);
ClubName = VariableLengthText(32);
ControlNumber = UnsignedInteger(32) restricted to {1..1000};
Course = VariableLengthText(16) restricted to {'A'..'E', 'PW'};
EntryID = AutoCounter();
EventID = AutoCounter();
EventName = VariableLengthText(50);
FamilyName = VariableLengthText(48);
Gender = FixedLengthText(1) restricted to {'M', 'F'};
GivenName = VariableLengthText(48);
Location = VariableLengthText(200);
MapID = AutoCounter();
MapName = VariableLengthText(80);
Number = UnsignedInteger(32) restricted to {1..100};
PersonID = AutoCounter();
Placing = UnsignedInteger(32);
PointValue = UnsignedInteger(32);
PostCode = UnsignedInteger(32);
PunchID = AutoCounter();
Score = SignedInteger(32);
ScoringMethod = VariableLengthText(32) restricted to {'Score', 'Scatter', 'Special'};
SeriesID = AutoCounter();
SeriesName = VariableLengthText(40);
StartTime = DateAndTime();
Time = DateAndTime();
Year = UnsignedInteger(32) restricted to {1900..3000};

/*
 * Entity Types
 */
Club = entity identified by ClubCode:
	Club has exactly one ClubCode,
	ClubCode is of at most one Club;
ClubName is name of at most one Club,
	Club is called exactly one ClubName;

Event = entity identified by EventID:
	Event has exactly one EventID,
	EventID is of at most one Event;
Event is called at most one EventName,
	EventName is name of at most one Event;
Event starts at exactly one start-Location,
	Location is where Event starts;
Event is held on exactly one StartTime;
EventScoringMethod = ScoringMethod is used for Course of Event;
Event has at most one Number;
Club runs Event,
	Event is run by exactly one Club;
EventControl = Event includes at least one ControlNumber;
EventControl has at most one PointValue;

Map = entity identified by MapID:
	Map has exactly one MapID,
	MapID is of at most one Map;
Map is map for Event,
	Event uses exactly one Map;
Map has exactly one MapName,
	MapName is of at most one Map;
Club (as Owner) owns Map,
	Map is owned by exactly one Owner;
Map has at most one Accessibility;

Person = entity identified by PersonID:
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
Entry = entity identified by EntryID:
	Entry has exactly one EntryID,
	EntryID is of at most one Entry;
Entry received at most one Score;
Entry finished in at most one finish-Placing;

Punch = entity identified by PunchID:
	Punch has exactly one PunchID,
	PunchID is of at most one Punch;
Visit = Punch was visited by Entry at Time;
PunchPlacement = Punch is placed at EventControl;

Series = entity identified by SeriesID:
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
