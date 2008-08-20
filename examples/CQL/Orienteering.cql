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
Club is identified by ClubCode where
	Club has exactly one ClubCode,
	ClubCode is of at most one Club;
ClubName is name of at most one Club,
	Club is called exactly one ClubName;

Event is identified by EventID where
	Event has exactly one EventID,
	EventID is of at most one Event;
Club runs Event,
	Event is run by exactly one Club;
Event is called at most one EventName,
	EventName is name of at most one Event;
Event has at most one Number;
Event is held on exactly one StartTime;
Event starts at exactly one start-Location,
	Location is where Event starts;
EventControl is where
	Event includes at least one ControlNumber;
EventScoringMethod is where
	ScoringMethod is used for Course of Event;
EventControl has at most one PointValue;

Map is identified by MapID where
	Map has exactly one MapID,
	MapID is of at most one Map;
Club (as Owner) owns Map,
	Map is owned by exactly one Owner;
Map has at most one Accessibility;
Map is map for Event,
	Event uses exactly one Map;
Map has exactly one MapName,
	MapName is of at most one Map;

Person is identified by PersonID where
	Person has exactly one PersonID,
	PersonID is of at most one Person;
Person is member of at most one Club;
Person has exactly one FamilyName,
	FamilyName is of Person;
Person is of at most one Gender;
Person has exactly one GivenName,
	GivenName is name of Person;
Person has at most one PostCode;
Person was born in at most one birth-Year;
Entry is identified by EntryID where
	Entry has exactly one EntryID,
	EntryID is of at most one Entry,
	Person entered at most one Course of Event;
Entry received at most one Score;
Entry finished in at most one finish-Placing;

Punch is identified by PunchID where
	Punch has exactly one PunchID,
	PunchID is of at most one Punch;
PunchPlacement is where
	Punch is placed at EventControl;
Visit is where
	Punch was visited by Entry at Time;

Series is identified by SeriesID where
	Series has exactly one SeriesID,
	SeriesID is of at most one Series;
Event is in at most one Series;
Series has exactly one SeriesName (as Name),
	Name is of at most one Series;

/*
 * Constraints:
Event is in Series
	if and only if
	Event has Number;
 */
each combination Course, Event occurs at most one time in
	ScoringMethod is used for Course of Event;
each Event occurs at least one time in
	Event is called EventName,
	Event is in Series;
each EventControl occurs at least one time in
	Punch is placed at EventControl;
each combination GivenName, FamilyName occurs at most one time in
	Person has GivenName,
	Person has FamilyName;
each combination Series, Number occurs at most one time in
	Event is in Series,
	Event has Number;
