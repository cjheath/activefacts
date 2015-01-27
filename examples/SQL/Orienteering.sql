CREATE TABLE Club (
	-- Club has Club Code,
	ClubCode                                varchar(6) NOT NULL,
	-- Club is called Club Name,
	ClubName                                varchar(32) NOT NULL,
	PRIMARY KEY(ClubCode),
	UNIQUE(ClubName)
)
GO

CREATE TABLE Entry (
	-- Entry (in which Person entered Course of Event) involves Course,
	Course                                  varchar(16) NOT NULL CHECK((Course >= 'A' AND Course <= 'E') OR Course = 'PW'),
	-- Entry has Entry ID,
	EntryID                                 int IDENTITY NOT NULL,
	-- Entry (in which Person entered Course of Event) and Event has Event ID,
	EventID                                 int NOT NULL,
	-- maybe Entry finished in finish-Placing,
	FinishPlacing                           int NULL,
	-- Entry (in which Person entered Course of Event) and Person has Person ID,
	PersonID                                int NOT NULL,
	-- maybe Entry received Score,
	Score                                   int NULL,
	PRIMARY KEY(EntryID),
	UNIQUE(PersonID, EventID)
)
GO

CREATE TABLE Event (
	-- Event is run by Club and Club has Club Code,
	ClubCode                                varchar(6) NOT NULL,
	-- Event has Event ID,
	EventID                                 int IDENTITY NOT NULL,
	-- maybe Event is called Event Name,
	EventName                               varchar(50) NULL,
	-- Event uses Map and Map has Map ID,
	MapID                                   int NOT NULL,
	-- maybe Event has Number,
	Number                                  int NULL CHECK((Number >= 1 AND Number <= 100)),
	-- maybe Event is in Series and Series has Series ID,
	SeriesID                                int NULL,
	-- Event starts at start-Location,
	StartLocation                           varchar(200) NOT NULL,
	-- Event is held on Start Time,
	StartTime                               datetime NOT NULL,
	PRIMARY KEY(EventID),
	FOREIGN KEY (ClubCode) REFERENCES Club (ClubCode)
)
GO

CREATE VIEW dbo.Event_Name (EventName) WITH SCHEMABINDING AS
	SELECT EventName FROM dbo.Event
	WHERE	EventName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_EventByEventName ON dbo.Event_Name(EventName)
GO

CREATE VIEW dbo.Event_SeriesIDNumber (SeriesID, Number) WITH SCHEMABINDING AS
	SELECT SeriesID, Number FROM dbo.Event
	WHERE	SeriesID IS NOT NULL
	  AND	Number IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_EventBySeriesIDNumber ON dbo.Event_SeriesIDNumber(SeriesID, Number)
GO

CREATE TABLE EventControl (
	-- Event Control (in which Event includes Control Number) involves Control Number,
	ControlNumber                           int NOT NULL CHECK((ControlNumber >= 1 AND ControlNumber <= 1000)),
	-- Event Control (in which Event includes Control Number) and Event has Event ID,
	EventID                                 int NOT NULL,
	-- maybe Event Control has Point Value,
	PointValue                              int NULL,
	PRIMARY KEY(EventID, ControlNumber),
	FOREIGN KEY (EventID) REFERENCES Event (EventID)
)
GO

CREATE TABLE EventScoringMethod (
	-- Event Scoring Method (in which Scoring Method is used for Course of Event) involves Course,
	Course                                  varchar(16) NOT NULL CHECK((Course >= 'A' AND Course <= 'E') OR Course = 'PW'),
	-- Event Scoring Method (in which Scoring Method is used for Course of Event) and Event has Event ID,
	EventID                                 int NOT NULL,
	-- Event Scoring Method (in which Scoring Method is used for Course of Event) involves Scoring Method,
	ScoringMethod                           varchar(32) NOT NULL CHECK(ScoringMethod = 'Scatter' OR ScoringMethod = 'Score' OR ScoringMethod = 'Special'),
	PRIMARY KEY(Course, EventID),
	FOREIGN KEY (EventID) REFERENCES Event (EventID)
)
GO

CREATE TABLE Map (
	-- maybe Map has Accessibility,
	Accessibility                           char(1) NULL CHECK((Accessibility >= 'A' AND Accessibility <= 'D')),
	-- Map has Map ID,
	MapID                                   int IDENTITY NOT NULL,
	-- Map has Map Name,
	MapName                                 varchar(80) NOT NULL,
	-- Map is owned by Club and Club has Club Code,
	OwnerCode                               varchar(6) NOT NULL,
	PRIMARY KEY(MapID),
	UNIQUE(MapName),
	FOREIGN KEY (OwnerCode) REFERENCES Club (ClubCode)
)
GO

CREATE TABLE Person (
	-- maybe Person was born in birth-Year,
	BirthYear                               int NULL CHECK((BirthYear >= 1900 AND BirthYear <= 3000)),
	-- maybe Person is member of Club and Club has Club Code,
	ClubCode                                varchar(6) NULL,
	-- Person has Family Name,
	FamilyName                              varchar(48) NOT NULL,
	-- maybe Person is of Gender,
	Gender                                  char(1) NULL CHECK(Gender = 'F' OR Gender = 'M'),
	-- Person has Given Name,
	GivenName                               varchar(48) NOT NULL,
	-- Person has Person ID,
	PersonID                                int IDENTITY NOT NULL,
	-- maybe Person has Post Code,
	PostCode                                int NULL,
	PRIMARY KEY(PersonID),
	UNIQUE(GivenName, FamilyName),
	FOREIGN KEY (ClubCode) REFERENCES Club (ClubCode)
)
GO

CREATE TABLE Punch (
	-- Punch has Punch ID,
	PunchID                                 int IDENTITY NOT NULL,
	PRIMARY KEY(PunchID)
)
GO

CREATE TABLE PunchPlacement (
	-- Punch Placement (in which Punch is placed at Event Control) and Event Control (in which Event includes Control Number) and Event has Event ID,
	EventControlEventID                     int NOT NULL,
	-- Punch Placement (in which Punch is placed at Event Control) and Event Control (in which Event includes Control Number) involves Control Number,
	EventControlNumber                      int NOT NULL,
	-- Punch Placement (in which Punch is placed at Event Control) and Punch has Punch ID,
	PunchID                                 int NOT NULL,
	PRIMARY KEY(PunchID, EventControlEventID, EventControlNumber),
	FOREIGN KEY (EventControlEventID, EventControlNumber) REFERENCES EventControl (EventID, ControlNumber),
	FOREIGN KEY (PunchID) REFERENCES Punch (PunchID)
)
GO

CREATE TABLE Series (
	-- Series has Series Name,
	Name                                    varchar(40) NOT NULL,
	-- Series has Series ID,
	SeriesID                                int IDENTITY NOT NULL,
	PRIMARY KEY(SeriesID),
	UNIQUE(Name)
)
GO

CREATE TABLE Visit (
	-- Visit (in which Punch was visited by Entry at Time) and Entry has Entry ID,
	EntryID                                 int NOT NULL,
	-- Visit (in which Punch was visited by Entry at Time) and Punch has Punch ID,
	PunchID                                 int NOT NULL,
	-- Visit (in which Punch was visited by Entry at Time) involves Time,
	Time                                    datetime NOT NULL,
	PRIMARY KEY(PunchID, EntryID, Time),
	FOREIGN KEY (EntryID) REFERENCES Entry (EntryID),
	FOREIGN KEY (PunchID) REFERENCES Punch (PunchID)
)
GO

ALTER TABLE Entry
	ADD FOREIGN KEY (EventID) REFERENCES Event (EventID)
GO

ALTER TABLE Entry
	ADD FOREIGN KEY (PersonID) REFERENCES Person (PersonID)
GO

ALTER TABLE Event
	ADD FOREIGN KEY (MapID) REFERENCES Map (MapID)
GO

ALTER TABLE Event
	ADD FOREIGN KEY (SeriesID) REFERENCES Series (SeriesID)
GO

