vocabulary OrienteeringER;

/*
 * Value Types
 */
Accessibility is written as Char;
Club Name is written as String;
Code is written as Char;
Control is written as Unsigned Integer(32);
Course is written as Char;
Date is written as Date Time;
Event Name is written as String;
ID is written as Auto Counter;
Location is written as String;
Name is written as String;
Number is written as Signed Integer(32);
Point Value is written as Unsigned Integer(32);
Series Name is written as String;

/*
 * Entity Types
 */
Club is where
	Code is of the club called at most one Club Name,
	the club called Club Name has at most one Code;

Map is where
	map-Name having Accessibility belongs to Club;

Series Event is where
	Series Name includes event-Number,
	event-Number is in Series Name;

Event is where
	event-ID is Series Event called Event Name run by Club using Map on Date at Location;

Event Control is where
	Event includes Control which is worth at most one Point Value;

Event Course is where
	Course is available at Event,
	Event offers Course;

/*
 * Constraints:
 */
each Club occurs at least one time in
	event-ID is Series Event called Event Name run by Club using Map on Date at Location;
each Event Name occurs at most one time in
	event-ID is Series Event called Event Name run by Club using Map on Date at Location;
each Event occurs at least one time in
	Event includes Control which is worth Point Value;
each ID occurs one time in
	event-ID is Series Event called Event Name run by Club using Map on Date at Location;
each Name occurs at most one time in
	map-Name having Accessibility belongs to Club;
each Series Event occurs at most one time in
	event-ID is Series Event called Event Name run by Club using Map on Date at Location;
