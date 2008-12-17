CREATE TABLE Club (
	ClubCode	varchar(6) NOT NULL,
	ClubName	varchar(32) NOT NULL,
	PRIMARY KEY(ClubCode)
)
GO

CREATE TABLE Entry (
	EntryID	int NOT NULL,
	Course	varchar(16) NOT NULL,
	EventID	int NOT NULL,
	FinishPlacing	int NULL,
	PersonID	int NOT NULL,
	Score	int NULL,
	PRIMARY KEY(EntryID)
)
GO

CREATE TABLE Event (
	EventID	int NOT NULL,
	ClubCode	varchar(6) NOT NULL,
	EventName	varchar(50) NULL,
	MapID	int NOT NULL,
	Number	int NULL,
	SeriesID	int NULL,
	StartLocation	varchar(200) NOT NULL,
	StartTime	DateAndTime NOT NULL,
	PRIMARY KEY(EventID),
	FOREIGN KEY(ClubCode)
	REFERENCES Club(ClubCode)
)
GO

CREATE TABLE EventControl (
	EventID	int NOT NULL,
	ControlNumber	int NOT NULL,
	PointValue	int NULL,
	PRIMARY KEY(EventID, ControlNumber),
	FOREIGN KEY(EventID)
	REFERENCES Event(EventID)
)
GO

CREATE TABLE EventScoringMethod (
	Course	varchar(16) NOT NULL,
	EventID	int NOT NULL,
	ScoringMethod	varchar(32) NOT NULL,
	PRIMARY KEY(Course, EventID),
	FOREIGN KEY(EventID)
	REFERENCES Event(EventID)
)
GO

CREATE TABLE Map (
	MapID	int NOT NULL,
	Accessibility	FixedLengthText(1) NULL,
	MapName	varchar(80) NOT NULL,
	OwnerCode	varchar(6) NOT NULL,
	PRIMARY KEY(MapID),
	FOREIGN KEY(OwnerCode)
	REFERENCES Club(ClubCode)
)
GO

CREATE TABLE Person (
	PersonID	int NOT NULL,
	BirthYear	int NULL,
	ClubCode	varchar(6) NULL,
	FamilyName	varchar(48) NOT NULL,
	Gender	FixedLengthText(1) NULL,
	GivenName	varchar(48) NOT NULL,
	PostCode	int NULL,
	PRIMARY KEY(PersonID),
	FOREIGN KEY(ClubCode)
	REFERENCES Club(ClubCode)
)
GO

CREATE TABLE Punch (
	PunchID	int NOT NULL,
	PRIMARY KEY(PunchID)
)
GO

CREATE TABLE PunchPlacement (
	PunchID	int NOT NULL,
	EventControlEventID	int NOT NULL,
	EventControlControlNumber	int NOT NULL,
	PRIMARY KEY(PunchID, EventControlEventID, EventControlControlNumber),
	FOREIGN KEY(PunchID)
	REFERENCES Punch(PunchID),
	FOREIGN KEY(EventControlEventID, EventControlControlNumber)
	REFERENCES EventControl(EventID, ControlNumber)
)
GO

CREATE TABLE Series (
	SeriesID	int NOT NULL,
	Name	varchar(40) NOT NULL,
	PRIMARY KEY(SeriesID)
)
GO

CREATE TABLE Visit (
	PunchID	int NOT NULL,
	EntryID	int NULL,
	Time	DateAndTime NOT NULL,
	UNIQUE(PunchID, EntryID, Time),
	FOREIGN KEY(PunchID)
	REFERENCES Punch(PunchID),
	FOREIGN KEY(EntryID)
	REFERENCES Entry(EntryID)
)
GO

ALTER TABLE Entry
	ADD FOREIGN KEY(EventID)
	REFERENCES Event(EventID)
GO

ALTER TABLE Entry
	ADD FOREIGN KEY(PersonID)
	REFERENCES Person(PersonID)
GO

ALTER TABLE Event
	ADD FOREIGN KEY(MapID)
	REFERENCES Map(MapID)
GO

ALTER TABLE Event
	ADD FOREIGN KEY(SeriesID)
	REFERENCES Series(SeriesID)
GO

