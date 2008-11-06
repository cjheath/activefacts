CREATE TABLE Club (
	ClubCode	varchar(6) NOT NULL,
	ClubName	varchar(32) NOT NULL,
	UNIQUE(ClubCode)
)
GO

CREATE TABLE Entry (
	EntryID	int NOT NULL,
	Course	varchar(16) NOT NULL,
	EventID	int NOT NULL,
	FinishPlacing	int NULL,
	PersonID	int NOT NULL,
	Score	int NULL,
	UNIQUE(EntryID)
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
	UNIQUE(EventID),
	FOREIGN KEY(ClubCode)
	REFERENCES Club(ClubCode)
)
GO

CREATE TABLE EventControl (
	ControlNumber	int NOT NULL,
	EventID	int NOT NULL,
	PointValue	int NULL,
	UNIQUE(EventID, ControlNumber),
	FOREIGN KEY(EventID)
	REFERENCES Event(EventID)
)
GO

CREATE TABLE EventScoringMethod (
	Course	varchar(16) NOT NULL,
	EventID	int NOT NULL,
	ScoringMethod	varchar(32) NOT NULL,
	UNIQUE(Course, EventID),
	FOREIGN KEY(EventID)
	REFERENCES Event(EventID)
)
GO

CREATE TABLE Map (
	MapID	int NOT NULL,
	Accessibility	FixedLengthText(1) NULL,
	MapName	varchar(80) NOT NULL,
	OwnerCode	varchar(6) NOT NULL,
	UNIQUE(MapID),
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
	UNIQUE(PersonID),
	FOREIGN KEY(ClubCode)
	REFERENCES Club(ClubCode)
)
GO

CREATE TABLE Punch (
	PunchID	int NOT NULL,
	UNIQUE(PunchID)
)
GO

CREATE TABLE PunchPlacement (
	EventControlControlNumber	int NOT NULL,
	EventControlEventID	int NOT NULL,
	PunchID	int NOT NULL,
	UNIQUE(PunchID, EventControlEventID, EventControlControlNumber),
	FOREIGN KEY(EventControlEventID, EventControlControlNumber)
	REFERENCES EventControl(EventID, ControlNumber),
	FOREIGN KEY(PunchID)
	REFERENCES Punch(PunchID)
)
GO

CREATE TABLE Series (
	SeriesID	int NOT NULL,
	Name	varchar(40) NOT NULL,
	UNIQUE(SeriesID)
)
GO

CREATE TABLE Visit (
	EntryID	int NULL,
	PunchID	int NOT NULL,
	Time	DateAndTime NOT NULL,
	UNIQUE(PunchID, EntryID, Time),
	FOREIGN KEY(EntryID)
	REFERENCES Entry(EntryID),
	FOREIGN KEY(PunchID)
	REFERENCES Punch(PunchID)
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

