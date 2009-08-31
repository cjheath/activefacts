vocabulary Orienteering;

/*
 * Value Types
 */
Accessibility is written as FixedLengthText(1) restricted to {'A'..'D'};
ClubCode is written as VariableLengthText(6);
ClubName is written as VariableLengthText(32);
ControlNumber is written as UnsignedInteger(32) restricted to {1..1000};
Course is written as VariableLengthText(16) restricted to {'A'..'E', 'PW'};
EntryID is written as AutoCounter;
EventID is written as AutoCounter;
EventName is written as VariableLengthText(50);
FamilyName is written as VariableLengthText(48);
Gender is written as FixedLengthText(1) restricted to {'F', 'M'};
GivenName is written as VariableLengthText(48);
Location is written as VariableLengthText(200);
MapID is written as AutoCounter;
MapName is written as VariableLengthText(80);
Number is written as UnsignedInteger(32) restricted to {1..100};
PersonID is written as AutoCounter;
Placing is written as UnsignedInteger(32);
PointValue is written as UnsignedInteger(32);
PostCode is written as UnsignedInteger(32);
PunchID is written as AutoCounter;
Score is written as SignedInteger(32);
ScoringMethod is written as VariableLengthText(32) restricted to {'Scatter', 'Score', 'Special'};
SeriesID is written as AutoCounter;
SeriesName is written as VariableLengthText(40);
StartTime is written as DateAndTime;
Time is written as DateAndTime;
Year is written as UnsignedInteger(32) restricted to {1900..3000};

/*
 * Entity Types
 */
Club is identified by its Code;
ClubName is name of at most one Club,
	Club is called one ClubName;

Event is identified by its ID;
Club runs Event,
	Event is run by one Club;
Event is called at most one EventName,
	EventName is name of at most one Event;
Event has at most one Number;
Event is held on one StartTime;
Event starts at one start-Location,
	Location is where Event starts;

EventControl is where
	Event includes at least one ControlNumber;
EventControl has at most one PointValue;

EventScoringMethod is where
	ScoringMethod is used for Course of Event,
	Course of Event uses at most one ScoringMethod;

Map is identified by its ID;
Club (as Owner) owns Map,
	Map is owned by one Owner;
Map has at most one Accessibility;
Map is map for Event,
	Event uses one Map;
Map has one MapName,
	MapName is of at most one Map;

Person is identified by its ID;
Person is member of at most one Club;
Person has one FamilyName,
	FamilyName is of Person;
Person is of at most one Gender;
Person has one GivenName,
	GivenName is name of Person;
Person has at most one PostCode;
Person was born in at most one birth-Year;

Punch is identified by its ID;

PunchPlacement is where
	Punch is placed at EventControl;

Series is identified by its ID;
Event is in at most one Series;
Series has one SeriesName (as Name),
	Name is of at most one Series;

Entry is identified by its ID where
	Person entered Course of Event,
	Person entered Event in at most one Course;
Entry received at most one Score;
Entry finished in at most one finish-Placing;

Visit is where
	Punch was visited by Entry at Time;

/*
 * Constraints:
 */
Event is in Series
	if and only if
	Event has Number;
either Event is called EventName or Event is in Series;
each EventControl occurs at least one time in
	Punch is placed at EventControl;
each combination GivenName, FamilyName occurs at most one time in
	Person has GivenName,
	Person has FamilyName;
each combination Series, Number occurs at most one time in
	Event is in Series,
	Event has Number;
