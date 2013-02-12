CREATE TABLE Booking (
	-- Booking is where Person booked Showing for Count,
	Count                                   smallint NOT NULL CHECK(Count >= 1),
	-- Booking is where Person booked Showing for Count and Person has PersonID,
	PersonID                                int NOT NULL,
	-- Booking is where Person booked Showing for Count and Showing is where Cinema shows Film on DateTime and Cinema has CinemaID,
	ShowingCinemaID                         int NOT NULL,
	-- Booking is where Person booked Showing for Count and Showing is where Cinema shows Film on DateTime and DateTime has DateTimeValue,
	ShowingDateTimeValue                    datetime NOT NULL,
	-- Booking is where Person booked Showing for Count and Showing is where Cinema shows Film on DateTime and Film has FilmID,
	ShowingFilmID                           int NOT NULL,
	PRIMARY KEY(PersonID, ShowingCinemaID, ShowingFilmID, ShowingDateTimeValue)
)
GO

CREATE TABLE Cinema (
	-- Cinema has CinemaID,
	CinemaID                                int IDENTITY NOT NULL,
	PRIMARY KEY(CinemaID)
)
GO

CREATE TABLE Film (
	-- Film has FilmID,
	FilmID                                  int IDENTITY NOT NULL,
	-- maybe Film has Name,
	Name                                    varchar NULL,
	PRIMARY KEY(FilmID)
)
GO

CREATE TABLE Person (
	-- Person has login-Name,
	LoginName                               varchar NOT NULL,
	-- Person has PersonID,
	PersonID                                int IDENTITY NOT NULL,
	PRIMARY KEY(PersonID)
)
GO

CREATE TABLE Seat (
	-- maybe Cinema has Seat and Cinema has CinemaID,
	CinemaID                                int NULL,
	-- Seat has Number,
	Number                                  smallint NOT NULL,
	-- Seat is in Row,
	Row                                     char(2) NOT NULL,
	-- maybe Seat is in Section and Section has SectionName,
	SectionName                             varchar NULL,
	UNIQUE(CinemaID, Row, Number),
	FOREIGN KEY (CinemaID) REFERENCES Cinema (CinemaID)
)
GO

CREATE TABLE SeatAllocation (
	-- SeatAllocation is where Booking has allocated-Seat and maybe Cinema has Seat and Cinema has CinemaID,
	AllocatedSeatCinemaID                   int NULL,
	-- SeatAllocation is where Booking has allocated-Seat and Seat has Number,
	AllocatedSeatNumber                     smallint NOT NULL,
	-- SeatAllocation is where Booking has allocated-Seat and Seat is in Row,
	AllocatedSeatRow                        char(2) NOT NULL,
	-- SeatAllocation is where Booking has allocated-Seat and Booking is where Person booked Showing for Count and Person has PersonID,
	BookingPersonID                         int NOT NULL,
	-- SeatAllocation is where Booking has allocated-Seat and Booking is where Person booked Showing for Count and Showing is where Cinema shows Film on DateTime and Cinema has CinemaID,
	BookingShowingCinemaID                  int NOT NULL,
	-- SeatAllocation is where Booking has allocated-Seat and Booking is where Person booked Showing for Count and Showing is where Cinema shows Film on DateTime and DateTime has DateTimeValue,
	BookingShowingDateTimeValue             datetime NOT NULL,
	-- SeatAllocation is where Booking has allocated-Seat and Booking is where Person booked Showing for Count and Showing is where Cinema shows Film on DateTime and Film has FilmID,
	BookingShowingFilmID                    int NOT NULL,
	UNIQUE(BookingPersonID, BookingShowingCinemaID, BookingShowingFilmID, BookingShowingDateTimeValue, AllocatedSeatCinemaID, AllocatedSeatRow, AllocatedSeatNumber),
	FOREIGN KEY (BookingPersonID, BookingShowingCinemaID, BookingShowingDateTimeValue, BookingShowingFilmID) REFERENCES Booking (PersonID, ShowingCinemaID, ShowingDateTimeValue, ShowingFilmID),
	FOREIGN KEY (AllocatedSeatCinemaID, AllocatedSeatNumber, AllocatedSeatRow) REFERENCES Seat (CinemaID, Number, Row)
)
GO

ALTER TABLE Booking
	ADD FOREIGN KEY (PersonID) REFERENCES Person (PersonID)
GO

