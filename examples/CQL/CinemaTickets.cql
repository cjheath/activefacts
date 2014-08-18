vocabulary CinemaTickets;

/*
 * Value Types
 */
Address Text is written as Text;
Booking Nr is written as Signed Integer(32);
Cinema ID is written as Auto Counter;
Collection Code is written as Signed Integer(32);
Day is written as Signed Integer(32) restricted to {1..31};
Encrypted Password is written as String;
Film ID is written as Auto Counter;
High Demand is written as Boolean;
Hour is written as Signed Integer(32) restricted to {0..23};
Minute is written as Signed Integer(32) restricted to {0..59};
Month Nr is written as Signed Integer(32) restricted to {1..12};
Name is written as String;
Number is written as Unsigned Integer(16) restricted to {1..};
Payment Method Code is written as String;
Person ID is written as Auto Counter;
Price is written as Money;
Row Nr is written as Char(2);
Seat Number is written as Unsigned Integer(16);
Section Name is written as String;
Year Nr is written as Signed Integer(32) restricted to {1900..9999};

/*
 * Entity Types
 */
Address is identified by its Text;

Cinema is identified by its ID;
Cinema has one Name,
	Name is of at most one Cinema;

Film is identified by its ID;
Film has one Name;

Month is identified by its Nr;

Payment Method is identified by its Code restricted to {'Card', 'Cash', 'Gift Voucher', 'Loyalty Voucher'};

Person is identified by its ID;
Person has at most one Encrypted Password;
Person has at most one login-Name,
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

Year is identified by its Nr;
Film was made in at most one Year;

AllocatableCinemaSection is where
	Cinema provides allocated seating in Section,
	Section of Cinema uses allocated seating;

Session Time is identified by Year and Month and Day and Hour and Minute where
	Session Time is in one Year,
	Session Time is in one Month,
	Session Time is on one Day,
	Session Time is at one Hour,
	Session Time is at one Minute;

Ticket Pricing is where
	tickets on Session Time at Cinema in Section for High Demand have one Price;

Session is where
	Cinema shows Film on Session Time,
	Film is showing on Session Time at Cinema,
	Cinema at Session Time is showing one Film;
/*
some Session (where some Cinema shows some Film on some Session Time) has some Seat where
    that Cinema contains some Row that contains that Seat;
*/
Session is high-demand;
Session uses allocated seating;

Booking is identified by its Nr where
	Person booked Session for one Number of places,
	Person booked Number of places for Session;
tickets for Booking are being mailed to at most one Address;
Booking has at most one Collection Code;
Booking is for seats in at most one Section;
tickets for Booking have been issued;

Places Paid is where
	Number of places for Booking have been paid for by Payment Method,
	Booking applied Payment Method for one Number of places;

Seat Allocation is where
	Booking has allocated-Seat,
	Seat is allocated to Booking;

/*
 * Constraints:
 */
for each Booking at most one of these holds:
	Booking has Collection Code,
	tickets for Booking are being mailed to Address;
Booking has allocated Seat
	only if Booking applied Payment Method for Number of places;
tickets for Booking are being mailed to Address
	only if tickets for Booking have been issued;
Person has login Name
	only if Person has Encrypted Password;
each combination Name, Year occurs at most one time in
	Film has Name,
	Film was made in Year;
Booking
    (in which Person booked Number of places for Session
	(in which Film is showing on Session Time at Cinema))
    has allocated-Seat
    only if Seat is in Row that is in Cinema;
