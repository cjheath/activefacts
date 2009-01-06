CREATE TABLE Club (
	ClubName                                varchar(32) NOT NULL,
	ClubCode                                varchar(6) NOT NULL,
	PRIMARY KEY(ClubCode)
)
GO

CREATE TABLE Entry (
	PersonID                                int NOT NULL,
	Course                                  varchar(16) NOT NULL CHECK((Course >= 'A' AND Course <= 'E') OR Course = 'PW'),
	EventID                                 int NOT NULL,
	Score                                   int NULL,
	FinishPlacing                           int NULL,
	EntryID                                 int IDENTITY NOT NULL,
	PRIMARY KEY(EntryID)
)
GO

CREATE TABLE Event (
	EventName                               varchar(50) NULL,
	MapID                                   int NOT NULL,
	StartLocation                           varchar(200) NOT NULL,
	EventID                                 int IDENTITY NOT NULL,
	StartTime                               datetime NOT NULL,
	SeriesID                                int NULL,
	Number                                  int NULL CHECK((Number >= 1 AND Number <= 100)),
	ClubCode                                varchar(6) NOT NULL,
	PRIMARY KEY(EventID),
	FOREIGN KEY (ClubCode) REFERENCES Club (ClubCode)
)
GO

CREATE TABLE EventControl (
	EventID                                 int NOT NULL,
	ControlNumber                           int NOT NULL CHECK((ControlNumber >= 1 AND ControlNumber <= 1000)),
	PointValue                              int NULL,
	PRIMARY KEY(EventID, ControlNumber),
	FOREIGN KEY (EventID) REFERENCES Event (EventID)
)
GO

CREATE TABLE EventScoringMethod (
	ScoringMethod                           varchar(32) NOT NULL CHECK(ScoringMethod = 'Score' OR ScoringMethod = 'Scatter' OR ScoringMethod = 'Special'),
	Course                                  varchar(16) NOT NULL CHECK((Course >= 'A' AND Course <= 'E') OR Course = 'PW'),
	EventID                                 int NOT NULL,
	PRIMARY KEY(Course, EventID),
	FOREIGN KEY (EventID) REFERENCES Event (EventID)
)
GO

CREATE TABLE Map (
	MapName                                 varchar(80) NOT NULL,
	OwnerCode                               varchar(6) NOT NULL,
	Accessibility                           char(1) NULL CHECK((Accessibility >= 'A' AND Accessibility <= 'D')),
	MapID                                   int IDENTITY NOT NULL,
	PRIMARY KEY(MapID),
	FOREIGN KEY (OwnerCode) REFERENCES Club (ClubCode)
)
GO

CREATE TABLE Person (
	FamilyName                              varchar(48) NOT NULL,
	GivenName                               varchar(48) NOT NULL,
	Gender                                  char(1) NULL CHECK(Gender = 'M' OR Gender = 'F'),
	BirthYear                               int NULL CHECK((BirthYear >= 1900 AND BirthYear <= 3000)),
	PostCode                                int NULL,
	ClubCode                                varchar(6) NULL,
	PersonID                                int IDENTITY NOT NULL,
	PRIMARY KEY(PersonID),
	FOREIGN KEY (ClubCode) REFERENCES Club (ClubCode)
)
GO

CREATE TABLE Punch (
	PunchID                                 int IDENTITY NOT NULL,
	PRIMARY KEY(PunchID)
)
GO

CREATE TABLE PunchPlacement (
	PunchID                                 int NOT NULL,
	EventControlEventID                     int NOT NULL,
	EventControlControlNumber               int NOT NULL,
	PRIMARY KEY(PunchID, EventControlEventID, EventControlControlNumber),
	FOREIGN KEY (PunchID) REFERENCES Punch (PunchID),
	FOREIGN KEY (EventControlEventID, EventControlControlNumber) REFERENCES EventControl (EventID, ControlNumber)
)
GO

CREATE TABLE Series (
	Name                                    varchar(40) NOT NULL,
	SeriesID                                int IDENTITY NOT NULL,
	PRIMARY KEY(SeriesID)
)
GO

CREATE TABLE Visit (
	PunchID                                 int NOT NULL,
	EntryID                                 int NOT NULL,
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

