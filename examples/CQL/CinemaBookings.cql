vocabulary CinemaBookings;

/*
 * Value Types
 */
Cinema ID is written as Auto Counter;
DateTime Value is written as Date Time;
Film ID is written as Auto Counter;
Name is written as String;
Number is written as Unsigned Integer(16) restricted to {1..};
Person ID is written as Auto Counter;
Row Nr is written as Char(2);
Seat Number is written as Unsigned Integer(16);
Section Name is written as String;

/*
 * Entity Types
 */
Cinema is identified by its ID;

DateTime is identified by its Value;

Film is identified by its ID;
Film has at most one Name;

Person is identified by its ID;
Person has one login-Name,
	Name is of at most one Person;

Row is identified by Cinema and Row Nr where
	Row is in one Cinema,
	Cinema contains Row,
	Row has one Row Nr,
	Row Nr is of Row;

Seat is identified by Row and Seat Number where
	Seat is in one Row,
	Row contains Seat,
	Seat has one Seat Number,
	Seat Number is of Seat;

Section is identified by its Name;
Seat is in at most one Section,
	Section contains Seat;

Session is where
	Cinema shows Film on DateTime,
	Film is showing on DateTime at Cinema,
	Cinema at DateTime is showing one Film;

Booking is where
	Person booked Session for one Number of seats,
	Person booked Number of seats for Session;
Booking is confirmed;

Seat Allocation is where
	Booking has allocated-Seat,
	Seat is allocated to Booking;

/*
 * Constraints:
 */
Booking (in which Person booked Session (in which Cinema shows Film on DateTime) for Number of seats) has allocated Seat
	only if Cinema contains Row that contains Seat;
