CREATE TABLE Event (
	-- Event has EventId,
	EventId                                 int IDENTITY NOT NULL,
	-- Event is held at Venue and Venue has VenueId,
	VenueId                                 int NOT NULL,
	PRIMARY KEY(EventId)
)
GO

CREATE TABLE Seat (
	-- Seat has Number,
	Number                                  int NOT NULL,
	-- Seat is in Reserve,
	Reserve                                 varchar(20) NOT NULL,
	-- Seat is in Row,
	Row                                     char(2) NOT NULL,
	-- Seat is at Venue and Venue has VenueId,
	VenueId                                 int NOT NULL,
	PRIMARY KEY(VenueId, Reserve, Row, Number)
)
GO

CREATE TABLE Ticket (
	-- Ticket is for Event and Event has EventId,
	EventId                                 int NOT NULL,
	-- Ticket is for Seat and Seat has Number,
	SeatNumber                              int NOT NULL,
	-- Ticket is for Seat and Seat is in Reserve,
	SeatReserve                             varchar(20) NOT NULL,
	-- Ticket is for Seat and Seat is in Row,
	SeatRow                                 char(2) NOT NULL,
	-- Ticket is for Seat and Seat is at Venue and Venue has VenueId,
	SeatVenueId                             int NOT NULL,
	PRIMARY KEY(EventId, SeatVenueId, SeatReserve, SeatRow, SeatNumber),
	FOREIGN KEY (EventId) REFERENCES Event (EventId),
	FOREIGN KEY (SeatNumber, SeatReserve, SeatRow, SeatVenueId) REFERENCES Seat (Number, Reserve, Row, VenueId)
)
GO

CREATE TABLE Venue (
	-- Venue has VenueId,
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

