CREATE TABLE Booking (
	-- Booking is confirmed,
	IsConfirmed                             bit NULL,
	-- Booking is where Person booked Showing for Number of seats,
	Number                                  smallint NOT NULL CHECK(Number >= 1),
	-- Booking is where Person booked Showing for Number of seats and Person has Person ID,
	PersonID                                int NOT NULL,
	-- Booking is where Person booked Showing for Number of seats and Showing is where Cinema shows Film on Date Time and Cinema has Cinema ID,
	ShowingCinemaID                         int NOT NULL,
	-- Booking is where Person booked Showing for Number of seats and Showing is where Cinema shows Film on Date Time and Date Time has Date Time Value,
	ShowingDateTimeValue                    datetime NOT NULL,
	-- Booking is where Person booked Showing for Number of seats and Showing is where Cinema shows Film on Date Time and Film has Film ID,
	ShowingFilmID                           int NOT NULL,
	PRIMARY KEY(PersonID, ShowingCinemaID, ShowingFilmID, ShowingDateTimeValue)
)
GO

CREATE TABLE Cinema (
	-- Cinema has Cinema ID,
	CinemaID                                int IDENTITY NOT NULL,
	PRIMARY KEY(CinemaID)
)
GO

CREATE TABLE Film (
	-- Film has Film ID,
	FilmID                                  int IDENTITY NOT NULL,
	-- maybe Film has Name,
	Name                                    varchar NULL,
	PRIMARY KEY(FilmID)
)
GO

CREATE TABLE Person (
	-- Person has login-Name,
	LoginName                               varchar NOT NULL,
	-- Person has Person ID,
	PersonID                                int IDENTITY NOT NULL,
	PRIMARY KEY(PersonID),
	UNIQUE(LoginName)
)
GO

CREATE TABLE Seat (
	-- Seat is in Row and Row is in Cinema and Cinema has Cinema ID,
	RowCinemaID                             int NOT NULL,
	-- Seat is in Row and Row has Row Nr,
	RowNr                                   char(2) NOT NULL,
	-- Seat has Seat Number,
	SeatNumber                              smallint NOT NULL,
	-- maybe Seat is in Section and Section has Section Name,
	SectionName                             varchar NULL,
	PRIMARY KEY(RowCinemaID, RowNr, SeatNumber),
	FOREIGN KEY (RowCinemaID) REFERENCES Cinema (CinemaID)
)
GO

CREATE TABLE SeatAllocation (
	-- Seat Allocation is where Booking has allocated-Seat and Seat has Seat Number,
	AllocatedSeatNumber                     smallint NOT NULL,
	-- Seat Allocation is where Booking has allocated-Seat and Seat is in Row and Row is in Cinema and Cinema has Cinema ID,
	AllocatedSeatRowCinemaID                int NOT NULL,
	-- Seat Allocation is where Booking has allocated-Seat and Seat is in Row and Row has Row Nr,
	AllocatedSeatRowNr                      char(2) NOT NULL,
	-- Seat Allocation is where Booking has allocated-Seat and Booking is where Person booked Showing for Number of seats and Person has Person ID,
	BookingPersonID                         int NOT NULL,
	-- Seat Allocation is where Booking has allocated-Seat and Booking is where Person booked Showing for Number of seats and Showing is where Cinema shows Film on Date Time and Cinema has Cinema ID,
	BookingShowingCinemaID                  int NOT NULL,
	-- Seat Allocation is where Booking has allocated-Seat and Booking is where Person booked Showing for Number of seats and Showing is where Cinema shows Film on Date Time and Date Time has Date Time Value,
	BookingShowingDateTimeValue             datetime NOT NULL,
	-- Seat Allocation is where Booking has allocated-Seat and Booking is where Person booked Showing for Number of seats and Showing is where Cinema shows Film on Date Time and Film has Film ID,
	BookingShowingFilmID                    int NOT NULL,
	PRIMARY KEY(BookingPersonID, BookingShowingCinemaID, BookingShowingFilmID, BookingShowingDateTimeValue, AllocatedSeatRowCinemaID, AllocatedSeatRowNr, AllocatedSeatNumber),
	FOREIGN KEY (BookingPersonID, BookingShowingCinemaID, BookingShowingFilmID, BookingShowingDateTimeValue) REFERENCES Booking (PersonID, ShowingCinemaID, ShowingFilmID, ShowingDateTimeValue),
	FOREIGN KEY (AllocatedSeatRowCinemaID, AllocatedSeatRowNr, AllocatedSeatNumber) REFERENCES Seat (RowCinemaID, RowNr, SeatNumber)
)
GO

ALTER TABLE Booking
	ADD FOREIGN KEY (ShowingCinemaID) REFERENCES Cinema (CinemaID)
GO

ALTER TABLE Booking
	ADD FOREIGN KEY (ShowingFilmID) REFERENCES Film (FilmID)
GO

ALTER TABLE Booking
	ADD FOREIGN KEY (PersonID) REFERENCES Person (PersonID)
GO

