CREATE TABLE Club (
	-- ClubName is name of Club,
	ClubName                                varchar(32) NOT NULL,
	-- Club has ClubCode,
	ClubCode                                varchar(6) NOT NULL,
	PRIMARY KEY(ClubCode)
)
GO

CREATE TABLE Entry (
	-- Entry is where Person entered Course of Event and Person has PersonID,
	PersonID                                int NOT NULL,
	-- Entry is where Person entered Course of Event,
	Course                                  varchar(16) NOT NULL CHECK((Course >= 'A' AND Course <= 'E') OR Course = 'PW'),
	-- Entry is where Person entered Course of Event and Event has EventID,
	EventID                                 int NOT NULL,
	-- maybe Entry received Score,
	Score                                   int NULL,
	-- maybe Entry finished in finish-Placing,
	FinishPlacing                           int NULL,
	-- Entry has EntryID,
	EntryID                                 int IDENTITY NOT NULL,
	PRIMARY KEY(EntryID)
)
GO

CREATE TABLE Event (
	-- maybe Event is called EventName,
	EventName                               varchar(50) NULL,
	-- Map is map for Event and Map has MapID,
	MapID                                   int NOT NULL,
	-- Event starts at start-Location,
	StartLocation                           varchar(200) NOT NULL,
	-- Event has EventID,
	EventID                                 int IDENTITY NOT NULL,
	-- Event is held on StartTime,
	StartTime                               datetime NOT NULL,
	-- maybe Event is in Series and Series has SeriesID,
	SeriesID                                int NULL,
	-- maybe Event has Number,
	Number                                  int NULL CHECK((Number >= 1 AND Number <= 100)),
	-- Club runs Event and Club has ClubCode,
	ClubCode                                varchar(6) NOT NULL,
	PRIMARY KEY(EventID),
	FOREIGN KEY (ClubCode) REFERENCES Club (ClubCode)
)
GO

CREATE TABLE EventControl (
	-- EventControl is where Event includes ControlNumber and Event has EventID,
	EventID                                 int NOT NULL,
	-- EventControl is where Event includes ControlNumber,
	ControlNumber                           int NOT NULL CHECK((ControlNumber >= 1 AND ControlNumber <= 1000)),
	-- maybe EventControl has PointValue,
	PointValue                              int NULL,
	PRIMARY KEY(EventID, ControlNumber),
	FOREIGN KEY (EventID) REFERENCES Event (EventID)
)
GO

CREATE TABLE EventScoringMethod (
	-- EventScoringMethod is where ScoringMethod is used for Course of Event,
	ScoringMethod                           varchar(32) NOT NULL CHECK(ScoringMethod = 'Score' OR ScoringMethod = 'Scatter' OR ScoringMethod = 'Special'),
	-- EventScoringMethod is where ScoringMethod is used for Course of Event,
	Course                                  varchar(16) NOT NULL CHECK((Course >= 'A' AND Course <= 'E') OR Course = 'PW'),
	-- EventScoringMethod is where ScoringMethod is used for Course of Event and Event has EventID,
	EventID                                 int NOT NULL,
	PRIMARY KEY(Course, EventID),
	FOREIGN KEY (EventID) REFERENCES Event (EventID)
)
GO

CREATE TABLE Map (
	-- Map has MapName,
	MapName                                 varchar(80) NOT NULL,
	-- Owner owns Map and Club has ClubCode,
	OwnerCode                               varchar(6) NOT NULL,
	-- maybe Map has Accessibility,
	Accessibility                           char(1) NULL CHECK((Accessibility >= 'A' AND Accessibility <= 'D')),
	-- Map has MapID,
	MapID                                   int IDENTITY NOT NULL,
	PRIMARY KEY(MapID),
	FOREIGN KEY (OwnerCode) REFERENCES Club (ClubCode)
)
GO

CREATE TABLE Person (
	-- Person has FamilyName,
	FamilyName                              varchar(48) NOT NULL,
	-- Person has GivenName,
	GivenName                               varchar(48) NOT NULL,
	-- maybe Person is of Gender,
	Gender                                  char(1) NULL CHECK(Gender = 'M' OR Gender = 'F'),
	-- maybe Person was born in birth-Year,
	BirthYear                               int NULL CHECK((BirthYear >= 1900 AND BirthYear <= 3000)),
	-- maybe Person has PostCode,
	PostCode                                int NULL,
	-- maybe Person is member of Club and Club has ClubCode,
	ClubCode                                varchar(6) NULL,
	-- Person has PersonID,
	PersonID                                int IDENTITY NOT NULL,
	PRIMARY KEY(PersonID),
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
	-- PunchPlacement is where Punch is placed at EventControl and Punch has PunchID,
	PunchID                                 int NOT NULL,
	-- PunchPlacement is where Punch is placed at EventControl and EventControl is where Event includes ControlNumber and Event has EventID,
	EventControlEventID                     int NOT NULL,
	-- PunchPlacement is where Punch is placed at EventControl and EventControl is where Event includes ControlNumber,
	EventControlControlNumber               int NOT NULL,
	PRIMARY KEY(PunchID, EventControlEventID, EventControlControlNumber),
	FOREIGN KEY (PunchID) REFERENCES Punch (PunchID),
	FOREIGN KEY (EventControlEventID, EventControlControlNumber) REFERENCES EventControl (EventID, ControlNumber)
)
GO

CREATE TABLE Series (
	-- Series has Name,
	Name                                    varchar(40) NOT NULL,
	-- Series has SeriesID,
	SeriesID                                int IDENTITY NOT NULL,
	PRIMARY KEY(SeriesID)
)
GO

CREATE TABLE Visit (
	-- Visit is where Punch was visited by Entry at Time and Punch has PunchID,
	PunchID                                 int NOT NULL,
	-- Visit is where Punch was visited by Entry at Time and Entry has EntryID,
	EntryID                                 int NOT NULL,
	-- Visit is where Punch was visited by Entry at Time,
	Time                                    datetime NOT NULL,
	PRIMARY KEY(PunchID, EntryID, Time),
	FOREIGN KEY (PunchID) REFERENCES Punch (PunchID),
	FOREIGN KEY (EntryID) REFERENCES Entry (EntryID)
)
GO

ALTER TABLE Entry
	ADD FOREIGN KEY (PersonID) REFERENCES Person (PersonID)
GO

ALTER TABLE Entry
	ADD FOREIGN KEY (EventID) REFERENCES Event (EventID)
GO

ALTER TABLE Event
	ADD FOREIGN KEY (MapID) REFERENCES Map (MapID)
GO

ALTER TABLE Event
	ADD FOREIGN KEY (SeriesID) REFERENCES Series (SeriesID)
GO

