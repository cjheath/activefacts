CREATE TABLE Club (
	Code                                    char NOT NULL,
	ClubName                                varchar NOT NULL,
	PRIMARY KEY(Code)
)
GO

CREATE TABLE Event (
	EventID                                 int IDENTITY NOT NULL,
	EventName                               varchar NOT NULL,
	ClubCode                                char NOT NULL,
	MapMapName                              varchar NOT NULL,
	Date                                    datetime NOT NULL,
	Location                                varchar NOT NULL,
	SeriesEventSeriesName                   varchar NOT NULL,
	SeriesEventEventNumber                  int NOT NULL,
	PRIMARY KEY(EventID),
	FOREIGN KEY (ClubCode) REFERENCES Club (Code)
)
GO

CREATE TABLE EventControl (
	EventEventID                            int NOT NULL,
	Control                                 int NOT NULL,
	PointValue                              int NOT NULL,
	PRIMARY KEY(EventEventID, Control),
	FOREIGN KEY (EventEventID) REFERENCES Event (EventID)
)
GO

CREATE TABLE EventCourse (
	Course                                  char NOT NULL,
	EventEventID                            int NOT NULL,
	PRIMARY KEY(Course, EventEventID),
	FOREIGN KEY (EventEventID) REFERENCES Event (EventID)
)
GO

CREATE TABLE Map (
	MapName                                 varchar NOT NULL,
	Accessibility                           char NOT NULL,
	ClubCode                                char NOT NULL,
	PRIMARY KEY(MapName),
	FOREIGN KEY (ClubCode) REFERENCES Club (Code)
)
GO

ALTER TABLE Event
	ADD FOREIGN KEY (MapMapName) REFERENCES Map (MapName)
GO

