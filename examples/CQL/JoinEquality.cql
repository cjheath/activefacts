vocabulary JoinEquality;

/*
 * Value Types
 */
EventId is written as AutoCounter;
Number is written as UnsignedSmallInteger(32);
Reserve is written as VariableLengthText(20);
Row is written as FixedLengthText(2);
VenueId is written as AutoCounter;

/*
 * Entity Types
 */
Event is identified by its Id;

Venue is identified by its Id;
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
Ticket is for Seat and Seat is at Venue
	if and only if
	Ticket is for Event and Event is held at Venue;
