vocabulary CinemaBookings;

/*
 * Value Types
 */
CinemaID is written as Auto Counter;
Count is written as Unsigned Integer(16) restricted to {1..};
DateTimeValue is written as Date Time;
FilmID is written as Auto Counter;
Name is written as String;
Number is written as Unsigned Integer(16);
PersonID is written as Auto Counter;
Row is written as Char(2);
SectionName is written as String;

/*
 * Entity Types
 */
Cinema is identified by its ID;

DateTime is identified by its Value;

Film is identified by its ID;
Film has at most one Name;

Person is identified by its ID;
Person has one login-Name,
	Name is of Person;

Seat is identified by Cinema and Row and Number where
	Cinema has Seat,
	Seat is in at most one Cinema,
	Seat is in one Row,
	Row contains Seat,
	Seat has one Number,
	Number is of Seat;

Section is identified by its Name;
Seat is in at most one Section,
	Section contains Seat;

Showing is where
	Cinema shows Film on DateTime,
	Film is showing on DateTime at Cinema;

Booking is where
	Person booked Showing for one Count,
	Person booked Count seats for Showing;

SeatAllocation is where
	Booking has allocated-Seat;

