CREATE TABLE Club (
	-- Club has ClubCode,
	ClubCode                                varchar(6) NOT NULL,
	-- ClubName is name of Club,
	ClubName                                varchar(32) NOT NULL,
	PRIMARY KEY(ClubCode),
	UNIQUE(ClubName)
)
GO

CREATE TABLE Entry (
	-- Entry is where Person entered Course of Event,
	Course                                  varchar(16) NOT NULL CHECK((Course >= 'A' AND Course <= 'E') OR Course = 'PW'),
	-- Entry has EntryID,
	EntryID                                 int IDENTITY NOT NULL,
	-- Entry is where Person entered Course of Event and Event has EventID,
	EventID                                 int NOT NULL,
	-- maybe Entry finished in finish-Placing,
	FinishPlacing                           int NULL,
	-- Entry is where Person entered Course of Event and Person has PersonID,
	PersonID                                int NOT NULL,
	-- maybe Entry received Score,
	Score                                   int NULL,
	PRIMARY KEY(EntryID),
	UNIQUE(PersonID, EventID)
)
GO

CREATE TABLE Event (
	-- Club runs Event and Club has ClubCode,
	ClubCode                                varchar(6) NOT NULL,
	-- Event has EventID,
	EventID                                 int IDENTITY NOT NULL,
	-- maybe Event is called EventName,
	EventName                               varchar(50) NULL,
	-- Map is map for Event and Map has MapID,
	MapID                                   int NOT NULL,
	-- maybe Event has Number,
	Number                                  int NULL CHECK((Number >= 1 AND Number <= 100)),
	-- maybe Event is in Series and Series has SeriesID,
	SeriesID                                int NULL,
	-- Event starts at start-Location,
	StartLocation                           varchar(200) NOT NULL,
	-- Event is held on StartTime,
	StartTime                               datetime NOT NULL,
	PRIMARY KEY(EventID),
	FOREIGN KEY (ClubCode) REFERENCES Club (ClubCode)
)
GO

CREATE VIEW dbo.Event_Name (EventName) WITH SCHEMABINDING AS
	SELECT EventName FROM dbo.Event
	WHERE	EventName IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX EventNameIsOfOneEvent ON dbo.Event_Name(EventName)
GO

CREATE VIEW dbo.Event_SeriesIDNumber (SeriesID, Number) WITH SCHEMABINDING AS
	SELECT SeriesID, Number FROM dbo.Event
	WHERE	SeriesID IS NOT NULL
	  AND	Number IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_EventBySeriesIDNumber ON dbo.Event_SeriesIDNumber(SeriesID, Number)
GO

CREATE TABLE EventControl (
	-- EventControl is where Event includes ControlNumber,
	ControlNumber                           int NOT NULL CHECK((ControlNumber >= 1 AND ControlNumber <= 1000)),
	-- EventControl is where Event includes ControlNumber and Event has EventID,
	EventID                                 int NOT NULL,
	-- maybe EventControl has PointValue,
	PointValue                              int NULL,
	PRIMARY KEY(EventID, ControlNumber),
	FOREIGN KEY (EventID) REFERENCES Event (EventID)
)
GO

CREATE TABLE EventScoringMethod (
	-- EventScoringMethod is where ScoringMethod is used for Course of Event,
	Course                                  varchar(16) NOT NULL CHECK((Course >= 'A' AND Course <= 'E') OR Course = 'PW'),
	-- EventScoringMethod is where ScoringMethod is used for Course of Event and Event has EventID,
	EventID                                 int NOT NULL,
	-- EventScoringMethod is where ScoringMethod is used for Course of Event,
	ScoringMethod                           varchar(32) NOT NULL CHECK(ScoringMethod = 'Scatter' OR ScoringMethod = 'Score' OR ScoringMethod = 'Special'),
	PRIMARY KEY(Course, EventID),
	FOREIGN KEY (EventID) REFERENCES Event (EventID)
)
GO

CREATE TABLE Map (
	-- maybe Map has Accessibility,
	Accessibility                           char(1) NULL CHECK((Accessibility >= 'A' AND Accessibility <= 'D')),
	-- Map has MapID,
	MapID                                   int IDENTITY NOT NULL,
	-- Map has MapName,
	MapName                                 varchar(80) NOT NULL,
	-- Owner owns Map and Club has ClubCode,
	OwnerCode                               varchar(6) NOT NULL,
	PRIMARY KEY(MapID),
	UNIQUE(MapName),
	FOREIGN KEY (OwnerCode) REFERENCES Club (ClubCode)
)
GO

CREATE TABLE Person (
	-- maybe Person was born in birth-Year,
	BirthYear                               int NULL CHECK((BirthYear >= 1900 AND BirthYear <= 3000)),
	-- maybe Person is member of Club and Club has ClubCode,
	ClubCode                                varchar(6) NULL,
	-- Person has FamilyName,
	FamilyName                              varchar(48) NOT NULL,
	-- maybe Person is of Gender,
	Gender                                  char(1) NULL CHECK(Gender = 'F' OR Gender = 'M'),
	-- Person has GivenName,
	GivenName                               varchar(48) NOT NULL,
	-- Person has PersonID,
	PersonID                                int IDENTITY NOT NULL,
	-- maybe Person has PostCode,
	PostCode                                int NULL,
	PRIMARY KEY(PersonID),
	UNIQUE(GivenName, FamilyName),
	FOREIGN KEY (ClubCode) REFERENCES Club (ClubCode)
)
GO

CREATE TABLE Punch (
	-- Punch has PunchID,
	PunchID                                 int IDENTITY NOT NULL,
	PRIMARY KEY(PunchID)
)
GO

CREATE TABLE PunchPlacement (
	-- PunchPlacement is where Punch is placed at EventControl and EventControl is where Event includes ControlNumber,
	EventControlNumber                      int NOT NULL,
	-- PunchPlacement is where Punch is placed at EventControl and EventControl is where Event includes ControlNumber and Event has EventID,
	EventControlEventID                     int NOT NULL,
	-- PunchPlacement is where Punch is placed at EventControl and Punch has PunchID,
	PunchID                                 int NOT NULL,
	PRIMARY KEY(PunchID, EventControlEventID, EventControlNumber),
	FOREIGN KEY (EventControlNumber, EventControlEventID) REFERENCES EventControl (ControlNumber, EventID),
	FOREIGN KEY (PunchID) REFERENCES Punch (PunchID)
)
GO

CREATE TABLE Series (
	-- Series has Name,
	Name                                    varchar(40) NOT NULL,
	-- Series has SeriesID,
	SeriesID                                int IDENTITY NOT NULL,
	PRIMARY KEY(SeriesID),
	UNIQUE(Name)
)
GO

CREATE TABLE Visit (
	-- Visit is where Punch was visited by Entry at Time and Entry has EntryID,
	EntryID                                 int NOT NULL,
	-- Visit is where Punch was visited by Entry at Time and Punch has PunchID,
	PunchID                                 int NOT NULL,
	-- Visit is where Punch was visited by Entry at Time,
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

