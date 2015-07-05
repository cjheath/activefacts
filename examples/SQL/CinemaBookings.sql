CREATE TABLE Booking (
	-- Booking is confirmed Boolean,
	IsConfirmed                             bit NULL,
	-- Booking involves Number,
	Number                                  smallint NOT NULL CHECK(Number >= 1),
	-- Booking involves Person and Person has Person ID,
	PersonID                                int NOT NULL,
	-- Booking involves Session and Session involves Cinema and Cinema has Cinema ID,
	SessionCinemaID                         int NOT NULL,
	-- Booking involves Session and Session involves DateTime and DateTime has DateTime Value,
	SessionDateTimeValue                    datetime NOT NULL,
	PRIMARY KEY(PersonID, SessionCinemaID, SessionDateTimeValue)
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
	-- Seat Allocation involves Seat and Seat has Seat Number,
	AllocatedSeatNumber                     smallint NOT NULL,
	-- Seat Allocation involves Seat and Seat is in Row and Row is in Cinema and Cinema has Cinema ID,
	AllocatedSeatRowCinemaID                int NOT NULL,
	-- Seat Allocation involves Seat and Seat is in Row and Row has Row Nr,
	AllocatedSeatRowNr                      char(2) NOT NULL,
	-- Seat Allocation involves Booking and Booking involves Person and Person has Person ID,
	BookingPersonID                         int NOT NULL,
	-- Seat Allocation involves Booking and Booking involves Session and Session involves Cinema and Cinema has Cinema ID,
	BookingSessionCinemaID                  int NOT NULL,
	-- Seat Allocation involves Booking and Booking involves Session and Session involves DateTime and DateTime has DateTime Value,
	BookingSessionDateTimeValue             datetime NOT NULL,
	PRIMARY KEY(BookingPersonID, BookingSessionCinemaID, BookingSessionDateTimeValue, AllocatedSeatRowCinemaID, AllocatedSeatRowNr, AllocatedSeatNumber),
	FOREIGN KEY (BookingPersonID, BookingSessionCinemaID, BookingSessionDateTimeValue) REFERENCES Booking (PersonID, SessionCinemaID, SessionDateTimeValue),
	FOREIGN KEY (AllocatedSeatRowCinemaID, AllocatedSeatRowNr, AllocatedSeatNumber) REFERENCES Seat (RowCinemaID, RowNr, SeatNumber)
)
GO

CREATE TABLE Session (
	-- Session involves Cinema and Cinema has Cinema ID,
	CinemaID                                int NOT NULL,
	-- Session involves DateTime and DateTime has DateTime Value,
	DateTimeValue                           datetime NOT NULL,
	-- Session involves Film and Film has Film ID,
	FilmID                                  int NOT NULL,
	PRIMARY KEY(CinemaID, DateTimeValue),
	FOREIGN KEY (CinemaID) REFERENCES Cinema (CinemaID),
	FOREIGN KEY (FilmID) REFERENCES Film (FilmID)
)
GO

ALTER TABLE Booking
	ADD FOREIGN KEY (PersonID) REFERENCES Person (PersonID)
GO

ALTER TABLE Booking
	ADD FOREIGN KEY (SessionCinemaID, SessionDateTimeValue) REFERENCES Session (CinemaID, DateTimeValue)
GO

