CREATE TABLE Club (
	-- Club is where Code is of the club called ClubName,
	ClubName                                varchar NOT NULL,
	-- Club is where Code is of the club called ClubName,
	Code                                    char NOT NULL,
	PRIMARY KEY(Code),
	UNIQUE(ClubName)
)
GO

CREATE TABLE Event (
	-- Event is where event-ID is SeriesEvent called EventName run by Club using Map on Date at Location and Club is where Code is of the club called ClubName,
	ClubCode                                char NOT NULL,
	-- Event is where event-ID is SeriesEvent called EventName run by Club using Map on Date at Location,
	Date                                    datetime NOT NULL,
	-- Event is where event-ID is SeriesEvent called EventName run by Club using Map on Date at Location,
	EventID                                 int IDENTITY NOT NULL,
	-- Event is where event-ID is SeriesEvent called EventName run by Club using Map on Date at Location,
	EventName                               varchar NOT NULL,
	-- Event is where event-ID is SeriesEvent called EventName run by Club using Map on Date at Location,
	Location                                varchar NOT NULL,
	-- Event is where event-ID is SeriesEvent called EventName run by Club using Map on Date at Location and Map is where map-Name having Accessibility belongs to Club,
	MapName                                 varchar NOT NULL,
	PRIMARY KEY(EventID),
	UNIQUE(EventName),
	FOREIGN KEY (ClubCode) REFERENCES Club (Code)
)
GO

CREATE TABLE EventControl (
	-- EventControl is where Event includes Control which is worth PointValue,
	Control                                 int NOT NULL,
	-- EventControl is where Event includes Control which is worth PointValue and Event is where event-ID is SeriesEvent called EventName run by Club using Map on Date at Location,
	EventID                                 int NOT NULL,
	-- EventControl is where Event includes Control which is worth PointValue,
	PointValue                              int NOT NULL,
	PRIMARY KEY(EventID, Control),
	FOREIGN KEY (EventID) REFERENCES Event (EventID)
)
GO

CREATE TABLE EventCourse (
	-- EventCourse is where Course is available at Event,
	Course                                  char NOT NULL,
	-- EventCourse is where Course is available at Event and Event is where event-ID is SeriesEvent called EventName run by Club using Map on Date at Location,
	EventID                                 int NOT NULL,
	PRIMARY KEY(Course, EventID),
	FOREIGN KEY (EventID) REFERENCES Event (EventID)
)
GO

CREATE TABLE Map (
	-- Map is where map-Name having Accessibility belongs to Club,
	Accessibility                           char NOT NULL,
	-- Map is where map-Name having Accessibility belongs to Club and Club is where Code is of the club called ClubName,
	ClubCode                                char NOT NULL,
	-- Map is where map-Name having Accessibility belongs to Club,
	MapName                                 varchar NOT NULL,
	PRIMARY KEY(MapName),
	FOREIGN KEY (ClubCode) REFERENCES Club (Code)
)
GO

CREATE TABLE SeriesEvent (
	-- maybe Event is where event-ID is SeriesEvent called EventName run by Club using Map on Date at Location and Event is where event-ID is SeriesEvent called EventName run by Club using Map on Date at Location,
	EventID                                 int NULL,
	-- SeriesEvent is where SeriesName includes event-Number,
	EventNumber                             int NOT NULL,
	-- SeriesEvent is where SeriesName includes event-Number,
	SeriesName                              varchar NOT NULL,
	PRIMARY KEY(SeriesName, EventNumber),
	FOREIGN KEY (EventID) REFERENCES Event (EventID)
)
GO

ALTER TABLE Event
	ADD FOREIGN KEY (MapName) REFERENCES Map (MapName)
GO

