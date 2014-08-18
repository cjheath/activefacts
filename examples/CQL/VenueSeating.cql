vocabulary VenueSeating;

/*
 * Value Types
 */
Event Id is written as Auto Counter;
Number is written as Unsigned Integer(16);
Reserve Name is written as String;
Row Code is written as Char;
Venue Id is written as Auto Counter;

/*
 * Entity Types
 */
Event is identified by its Id;

Reserve is identified by its Name;

Row is identified by its Code;

Venue is independent identified by its Id;
Event is held at one Venue,
	Venue hosts Event;

Seat is independent identified by Venue and Reserve and Row and Number where
	Seat is at one Venue,
	Venue has Seat,
	Seat is in one Reserve,
	Reserve contains Seat,
	Seat is in one Row,
	Row contains Seat,
	Seat has one Number,
	Number is of Seat;

Ticket is identified by Event and Seat where
	Ticket is for one Event,
	Event issued Ticket,
	Ticket is for one Seat;

/*
 * Constraints:
 */
Ticket is for Seat that is at Venue
	if and only if
	Ticket is for Event that is held at Venue;
