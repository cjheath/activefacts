CREATE TABLE Map (
	MapName	varchar NOT NULL,
	Accessibility	Accessibility NOT NULL,
	ClubCode	Code NOT NULL,
	PRIMARY KEY(MapName)
)
GO

CREATE TABLE Event (
	EventID	int NOT NULL,
	EventName	varchar NOT NULL,
	Date	Date NOT NULL,
	Location	varchar NOT NULL,
	MapMapName	varchar NOT NULL,
	SeriesEventEventNumber	int NOT NULL,
	SeriesEventSeriesName	varchar NOT NULL,
	ClubCode	Code NOT NULL,
	PRIMARY KEY(EventID)
)
GO

CREATE TABLE EventCourse (
	Course	Course NOT NULL,
	EventEventID	int NOT NULL,
	PRIMARY KEY(Course, EventEventID)
)
GO

CREATE TABLE EventControl (
	PointValue	int NOT NULL,
	Control	int NOT NULL,
	EventEventID	int NOT NULL,
	PRIMARY KEY(EventEventID, Control)
)
GO

CREATE TABLE Club (
	Code	Code NOT NULL,
	ClubName	varchar NOT NULL,
	PRIMARY KEY(Code)
)
GO

