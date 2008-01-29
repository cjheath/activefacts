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
PointValue = UnsignedInteger(32);
Position = UnsignedInteger(32);
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
Club = entity known by ClubCode:
	Club has exactly one ClubCode,
	ClubCode is of at most one Club;
ClubName is name of at most one Club,
	Club is called exactly one ClubName;

Entry = entity known by EntryID:
	Entry has exactly one EntryID,
	EntryID is of at most one Entry;
Entry received at most one Score;
Entry finished in at most one finish-Position;

Event = entity known by EventID:
	Event has exactly one EventID,
	EventID is of at most one Event;
Event is called at most one EventName,
	EventName is name of at most one Event;
start-Location is where Event starts,
	Event starts at exactly one start-Location;
Event is held on exactly one StartTime;
EventScoringMethod = ScoringMethod is used for Course of Event;
ControlValue = ControlNumber for Event has at most one PointValue;
Event has at most one Number;
Club runs Event,
	Event is run by exactly one Club;

Map = entity known by MapID:
	Map has exactly one MapID,
	MapID is of at most one Map;
Map is map for Event,
	Event uses exactly one Map;
Map has exactly one MapName,
	MapName is of at most one Map;
Club owns Map,
	Map is owned by exactly one Club;
Map has at most one Accessibility;

Person = entity known by PersonID:
	Person has exactly one PersonID,
	PersonID is of at most one Person;
Person has exactly one FamilyName,
	FamilyName is of Person;
Person has exactly one GivenName,
	GivenName is name of Person;
Person is of at most one Gender;
Person was born in at most one Year;
Person has at most one PostCode;
Person is a member of at most one Club;

Punch = entity known by PunchID:
	Punch has exactly one PunchID,
	PunchID is of at most one Punch;
Visit = Punch was visited by Entry at Time;
PunchPlacement = Event has Punch at at most one ControlNumber;

Series = entity known by SeriesID:
	Series has exactly one SeriesID,
	SeriesID is of at most one Series;
Series has exactly one SeriesName,
	SeriesName is of at most one Series;
Event is in at most one Series;

/*
Constraints:
	CompetitorHasDistinctName: each combination(PersonHasGivenName.GivenName, PersonHasFamilyName.FamilyName) may occur at most 1 time
	EqualityConstraint EqualityConstraint1 between EventIsInSeries(Event), EventHasNumber(Event)
	EventHasSeriesNumberOrName: each combination(EventIsCalledEventName.Event, EventIsInSeries.Event) must occur at least 1 time
	ExternalUniquenessConstraint1: each combination(EventIsInSeries.Series, EventHasNumber.Number) may occur at most 1 time
	OnlyOneScoringMethodForEachEventAndCourse: in EventScoringMethod, each combination (Course, Event) may occur at most 1 time
	PersonMayEnterEventOnce: in Entry, each combination (Person, Event) may occur at most 1 time
 */
