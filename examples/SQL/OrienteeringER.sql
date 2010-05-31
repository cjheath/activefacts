CREATE TABLE Club (
	-- Club is where Code is of the club called Club Name,
	ClubName                                varchar NOT NULL,
	-- Club is where Code is of the club called Club Name,
	Code                                    char NOT NULL,
	PRIMARY KEY(Code),
	UNIQUE(ClubName)
)
GO

CREATE TABLE Event (
	-- Event is where event-ID is Series Event called Event Name run by Club using Map on Date at Location and Club is where Code is of the club called Club Name,
	ClubCode                                char NOT NULL,
	-- Event is where event-ID is Series Event called Event Name run by Club using Map on Date at Location,
	Date                                    datetime NOT NULL,
	-- Event is where event-ID is Series Event called Event Name run by Club using Map on Date at Location,
	EventID                                 int IDENTITY NOT NULL,
	-- Event is where event-ID is Series Event called Event Name run by Club using Map on Date at Location,
	EventName                               varchar NOT NULL,
	-- Event is where event-ID is Series Event called Event Name run by Club using Map on Date at Location,
	Location                                varchar NOT NULL,
	-- Event is where event-ID is Series Event called Event Name run by Club using Map on Date at Location and Map is where map-Name having Accessibility belongs to Club,
	MapName                                 varchar NOT NULL,
	PRIMARY KEY(EventID),
	UNIQUE(EventName),
	FOREIGN KEY (ClubCode) REFERENCES Club (Code)
)
GO

CREATE TABLE EventControl (
	-- Event Control is where Event includes Control which is worth Point Value,
	Control                                 int NOT NULL,
	-- Event Control is where Event includes Control which is worth Point Value and Event is where event-ID is Series Event called Event Name run by Club using Map on Date at Location,
	EventID                                 int NOT NULL,
	-- Event Control is where Event includes Control which is worth Point Value,
	PointValue                              int NOT NULL,
	PRIMARY KEY(EventID, Control),
	FOREIGN KEY (EventID) REFERENCES Event (EventID)
)
GO

CREATE TABLE EventCourse (
	-- Event Course is where Course is available at Event,
	Course                                  char NOT NULL,
	-- Event Course is where Course is available at Event and Event is where event-ID is Series Event called Event Name run by Club using Map on Date at Location,
	EventID                                 int NOT NULL,
	PRIMARY KEY(Course, EventID),
	FOREIGN KEY (EventID) REFERENCES Event (EventID)
)
GO

CREATE TABLE Map (
	-- Map is where map-Name having Accessibility belongs to Club,
	Accessibility                           char NOT NULL,
	-- Map is where map-Name having Accessibility belongs to Club and Club is where Code is of the club called Club Name,
	ClubCode                                char NOT NULL,
	-- Map is where map-Name having Accessibility belongs to Club,
	MapName                                 varchar NOT NULL,
	PRIMARY KEY(MapName),
	FOREIGN KEY (ClubCode) REFERENCES Club (Code)
)
GO

CREATE TABLE SeriesEvent (
	-- maybe Event is where event-ID is Series Event called Event Name run by Club using Map on Date at Location and Event is where event-ID is Series Event called Event Name run by Club using Map on Date at Location,
	EventID                                 int NULL,
	-- Series Event is where Series Name includes event-Number,
	EventNumber                             int NOT NULL,
	-- Series Event is where Series Name includes event-Number,
	SeriesName                              varchar NOT NULL,
	PRIMARY KEY(SeriesName, EventNumber),
	FOREIGN KEY (EventID) REFERENCES Event (EventID)
)
GO

ALTER TABLE Event
	ADD FOREIGN KEY (MapName) REFERENCES Map (MapName)
GO

