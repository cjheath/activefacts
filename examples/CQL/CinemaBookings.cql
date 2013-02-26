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

/* This constraint compiles cleanly, but breaks the verbaliser on output */
/* The parser doesn't like "... has some allocated Seat" without the hyphen - fix? */
some Booking
    (in which some Person booked some Count seats for some Showing
	(in which some Film is showing on some DateTime at some Cinema))
    has allocated Seat
    only if that Seat is in that Cinema;

/* This constraint doesn't compile, but should (and could, if the "in involved in" readings were available):
Booking has allocated Seat only if
    Booking is involved in some Showing that involves some Cinema that has that Seat;
*/

/* This constraint compiles cleanly and re-verbalises, but requires additional fact types
Booking is confirmed;
Showing is late;
Booking has allocated Seat only if
    Seat is in Cinema
    and Booking (in which Person booked Showing for Count) is confirmed
    and Showing (in which Cinema shows Film on DateTime) is late;
*/
