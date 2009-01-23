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
	MapMapName                              varchar NOT NULL,
	-- Event is where event-ID is SeriesEvent called EventName run by Club using Map on Date at Location and SeriesEvent is where SeriesName includes event-Number,
	SeriesEventEventNumber                  int NOT NULL,
	-- Event is where event-ID is SeriesEvent called EventName run by Club using Map on Date at Location and SeriesEvent is where SeriesName includes event-Number,
	SeriesEventSeriesName                   varchar NOT NULL,
	PRIMARY KEY(EventID),
	UNIQUE(EventName),
	UNIQUE(SeriesEventSeriesName, SeriesEventEventNumber),
	FOREIGN KEY (ClubCode) REFERENCES Club (Code)
)
GO

CREATE TABLE EventControl (
	-- EventControl is where Event includes Control which is worth PointValue,
	Control                                 int NOT NULL,
	-- EventControl is where Event includes Control which is worth PointValue and Event is where event-ID is SeriesEvent called EventName run by Club using Map on Date at Location,
	EventEventID                            int NOT NULL,
	-- EventControl is where Event includes Control which is worth PointValue,
	PointValue                              int NOT NULL,
	PRIMARY KEY(EventEventID, Control),
	FOREIGN KEY (EventEventID) REFERENCES Event (EventID)
)
GO

CREATE TABLE EventCourse (
	-- EventCourse is where Course is available at Event,
	Course                                  char NOT NULL,
	-- EventCourse is where Course is available at Event and Event is where event-ID is SeriesEvent called EventName run by Club using Map on Date at Location,
	EventEventID                            int NOT NULL,
	PRIMARY KEY(Course, EventEventID),
	FOREIGN KEY (EventEventID) REFERENCES Event (EventID)
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

ALTER TABLE Event
	ADD FOREIGN KEY (MapMapName) REFERENCES Map (MapName)
GO

