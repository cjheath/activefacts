CREATE TABLE Event (
	-- Event has Event Id,
	EventId                                 int IDENTITY NOT NULL,
	-- Event is held at Venue and Venue has Venue Id,
	VenueId                                 int NOT NULL,
	PRIMARY KEY(EventId)
)
GO

CREATE TABLE Seat (
	-- Seat has Number,
	Number                                  smallint NOT NULL,
	-- Seat is in Reserve and Reserve has Reserve Name,
	ReserveName                             varchar NOT NULL,
	-- Seat is in Row and Row has Row Code,
	RowCode                                 char NOT NULL,
	-- Seat is at Venue and Venue has Venue Id,
	VenueId                                 int NOT NULL,
	PRIMARY KEY(VenueId, ReserveName, RowCode, Number)
)
GO

CREATE TABLE Ticket (
	-- Ticket is for Event and Event has Event Id,
	EventId                                 int NOT NULL,
	-- Ticket is for Seat and Seat has Number,
	SeatNumber                              smallint NOT NULL,
	-- Ticket is for Seat and Seat is in Reserve and Reserve has Reserve Name,
	SeatReserveName                         varchar NOT NULL,
	-- Ticket is for Seat and Seat is in Row and Row has Row Code,
	SeatRowCode                             char NOT NULL,
	-- Ticket is for Seat and Seat is at Venue and Venue has Venue Id,
	SeatVenueId                             int NOT NULL,
	PRIMARY KEY(EventId, SeatVenueId, SeatReserveName, SeatRowCode, SeatNumber),
	FOREIGN KEY (EventId) REFERENCES Event (EventId),
	FOREIGN KEY (SeatVenueId, SeatReserveName, SeatRowCode, SeatNumber) REFERENCES Seat (VenueId, ReserveName, RowCode, Number)
)
GO

CREATE TABLE Venue (
	-- Venue has Venue Id,
	VenueId                                 int IDENTITY NOT NULL,
	PRIMARY KEY(VenueId)
)
GO

ALTER TABLE Event
	ADD FOREIGN KEY (VenueId) REFERENCES Venue (VenueId)
GO

ALTER TABLE Seat
	ADD FOREIGN KEY (VenueId) REFERENCES Venue (VenueId)
GO

