vocabulary JoinEquality;

/*
 * Value Types
 */
EventId is defined as AutoCounter();
Number is defined as UnsignedSmallInteger(32);
Reserve is defined as VariableLengthText(20);
Row is defined as FixedLengthText(2);
SeatId is defined as AutoCounter();
VenueId is defined as AutoCounter();

/*
 * Entity Types
 */
Event is identified by its Id;

Venue is identified by its Id;
Event is held at one Venue;

Seat is identified by Venue and Reserve and Row and Number where
	Seat is at one Venue,
	Seat is in one Reserve,
	Seat is in one Row,
	Seat has one Number;
Seat has one SeatId,
	SeatId is of at most one Seat;

Ticket is identified by Event and Seat where
	Ticket is for one Event,
	Ticket is for one Seat;

/*
 * Constraints:
 */
Ticket is for Seat and Seat is at Venue
	if and only if
	Ticket is for Event and Event is held at Venue;
