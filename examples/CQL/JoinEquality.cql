vocabulary JoinEquality;

/*
 * Value Types
 */
Event Id is written as Auto Counter;
Number is written as Unsigned Integer(16);
Reserve is written as String(20);
Row is written as Char(2);
Venue Id is written as Auto Counter;

/*
 * Entity Types
 */
Event is identified by its Id;

Venue is identified by its Id [independent];
Event is held at one Venue;

Seat is identified by Venue and Reserve and Row and Number [independent] where
	Seat is at one Venue,
	Seat is in one Reserve,
	Seat is in one Row,
	Seat has one Number;

Ticket is identified by Event and Seat where
	Ticket is for one Event,
	Ticket is for one Seat;

/*
 * Constraints:
 */
Ticket is for Seat that is at Venue
	if and only if
	Ticket is for Event that is held at Venue;
