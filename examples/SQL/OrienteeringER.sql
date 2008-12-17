CREATE TABLE Club (
	Code	FixedLengthText NOT NULL,
	ClubName	varchar NOT NULL,
	PRIMARY KEY(Code)
)
GO

CREATE TABLE Event (
	EventID	int NOT NULL,
	ClubCode	FixedLengthText NOT NULL,
	Date	DateAndTime NOT NULL,
	EventName	varchar NOT NULL,
	Location	varchar NOT NULL,
	MapMapName	varchar NOT NULL,
	SeriesEventEventNumber	int NOT NULL,
	SeriesEventSeriesName	varchar NOT NULL,
	PRIMARY KEY(EventID),
	FOREIGN KEY(ClubCode)
	REFERENCES Club(Code)
)
GO

CREATE TABLE EventControl (
	EventEventID	int NOT NULL,
	Control	int NOT NULL,
	PointValue	int NOT NULL,
	PRIMARY KEY(EventEventID, Control),
	FOREIGN KEY(EventEventID)
	REFERENCES Event(EventID)
)
GO

CREATE TABLE EventCourse (
	Course	FixedLengthText NOT NULL,
	EventEventID	int NOT NULL,
	PRIMARY KEY(Course, EventEventID),
	FOREIGN KEY(EventEventID)
	REFERENCES Event(EventID)
)
GO

CREATE TABLE Map (
	MapName	varchar NOT NULL,
	Accessibility	FixedLengthText NOT NULL,
	ClubCode	FixedLengthText NOT NULL,
	PRIMARY KEY(MapName),
	FOREIGN KEY(ClubCode)
	REFERENCES Club(Code)
)
GO

ALTER TABLE Event
	ADD FOREIGN KEY(MapMapName)
	REFERENCES Map(MapName)
GO

