CREATE TABLE Event (
	-- Event has EventId,
	EventId                                 AutoCounter IDENTITY NOT NULL,
	-- Event is held at Venue and Venue has VenueId,
	VenueId                                 AutoCounter NOT NULL,
	PRIMARY KEY(EventId)
)
GO

CREATE TABLE Seat (
	-- Seat has SeatId,
	SeatId                                  AutoCounter NOT NULL,
	-- Seat is at Venue and Venue has VenueId,
	VenueId                                 AutoCounter NOT NULL,
	-- Seat is in Reserve,
	Reserve                                 VariableLengthText(20) NOT NULL,
	-- Seat is in Row,
	Row                                     FixedLengthText(2) NOT NULL,
	-- Seat has Number,
	Number                                  UnsignedSmallInteger(32) NOT NULL,
	PRIMARY KEY(VenueId, Reserve, Row, Number),
	UNIQUE(SeatId)
)
GO

CREATE TABLE Ticket (
	-- Ticket is for Seat and Seat is at Venue and Venue has VenueId,
	SeatVenueId                             AutoCounter NOT NULL,
	-- Ticket is for Seat and Seat is in Reserve,
	SeatReserve                             VariableLengthText(20) NOT NULL,
	-- Ticket is for Seat and Seat is in Row,
	SeatRow                                 FixedLengthText(2) NOT NULL,
	-- Ticket is for Seat and Seat has Number,
	SeatNumber                              UnsignedSmallInteger(32) NOT NULL,
	-- Ticket is for Event and Event has EventId,
	EventId                                 AutoCounter NOT NULL,
	PRIMARY KEY(EventId, SeatVenueId, SeatReserve, SeatRow, SeatNumber),
	FOREIGN KEY (SeatVenueId, SeatReserve, SeatRow, SeatNumber) REFERENCES Seat (VenueId, Reserve, Row, Number),
	FOREIGN KEY (EventId) REFERENCES Event (EventId)
)
GO

CREATE TABLE Venue (
	-- Venue has VenueId,
	VenueId                                 AutoCounter IDENTITY NOT NULL,
	PRIMARY KEY(VenueId)
)
GO

ALTER TABLE Event
	ADD FOREIGN KEY (VenueId) REFERENCES Venue (VenueId)
GO

ALTER TABLE Seat
	ADD FOREIGN KEY (VenueId) REFERENCES Venue (VenueId)
GO

