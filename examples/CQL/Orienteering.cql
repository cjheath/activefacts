vocabulary Orienteering;

/*
 * Value Types
 */
Accessibility is written as Char(1) restricted to {'A'..'D'};
Club Code is written as String(6);
Club Name is written as String(32);
Control Number is written as Unsigned Integer(32) restricted to {1..1000};
Course is written as String(16) restricted to {'A'..'E', 'PW'};
Entry ID is written as Auto Counter;
Event ID is written as Auto Counter;
Event Name is written as String(50);
Family Name is written as String(48);
Gender is written as Char(1) restricted to {'F', 'M'};
Given Name is written as String(48);
Location is written as String(200);
Map ID is written as Auto Counter;
Map Name is written as String(80);
Number is written as Unsigned Integer(32) restricted to {1..100};
Person ID is written as Auto Counter;
Placing is written as Unsigned Integer(32);
Point Value is written as Unsigned Integer(32);
Post Code is written as Unsigned Integer(32);
Punch ID is written as Auto Counter;
Score is written as Signed Integer(32);
Scoring Method is written as String(32) restricted to {'Scatter', 'Score', 'Special'};
Series ID is written as Auto Counter;
Series Name is written as String(40);
Start Time is written as Date Time;
Time is written as Date Time;
Year is written as Unsigned Integer(32) restricted to {1900..3000};

/*
 * Entity Types
 */
Club is identified by its Code;
Club Name is name of at most one Club,
	Club is called one Club Name;

Event is identified by its ID;
Club runs Event,
	Event is run by one Club;
Event is called at most one Event Name,
	Event Name is name of at most one Event;
Event has at most one Number;
Event is held on one Start Time;
Event starts at one start-Location,
	Location is place Event starts;

Event Control is where
	Event includes at least one Control Number;
Event Control has at most one Point Value;

Event Scoring Method is where
	Scoring Method is used for Course of Event,
	Course of Event uses one Scoring Method;

Map is identified by its ID;
Club (as Owner) owns Map,
	Map is owned by one Owner;
Map has at most one Accessibility;
Map is map for Event,
	Event uses one Map;
Map has one Map Name,
	Map Name is of at most one Map;

Person is identified by its ID;
Person is member of at most one Club;
Person has one Family Name,
	Family Name is of Person;
Person is of at most one Gender;
Person has one Given Name,
	Given Name is name of Person;
Person has at most one Post Code;
Person was born in at most one birth-Year;

Punch is identified by its ID;

Punch Placement is where
	Punch is placed at Event Control;

Series is identified by its ID;
Event is in at most one Series;
Series has one Series Name (as Name),
	Name is of at most one Series;

Entry is identified by its ID where
	Person entered Course of Event,
	Person entered Event in one Course;
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
each Event Control occurs at least one time in
	Punch is placed at Event Control;
either Event is called Event Name or Event is in Series;
each combination Given Name, Family Name occurs at most one time in
	Person has Given Name,
	Person has Family Name;
each combination Series, Number occurs at most one time in
	Event is in Series,
	Event has Number;
