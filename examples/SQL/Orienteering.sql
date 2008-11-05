CREATE TABLE Event (
	ClubCode	varchar(6) NOT NULL,
	MapID	int NOT NULL,
	SeriesID	int NULL,
	StartTime	StartTime NOT NULL,
	EventName	varchar(50) NULL,
	EventID	int NOT NULL,
	StartLocation	varchar(200) NOT NULL,
	Number	int NULL,
	UNIQUE(EventID)
)
GO

CREATE TABLE Club (
	ClubName	varchar(32) NOT NULL,
	ClubCode	varchar(6) NOT NULL,
	UNIQUE(ClubCode)
)
GO

CREATE TABLE Map (
	OwnerCode	varchar(6) NOT NULL,
	MapName	varchar(80) NOT NULL,
	Accessibility	Accessibility(1) NULL,
	MapID	int NOT NULL,
	UNIQUE(MapID)
)
GO

CREATE TABLE Person (
	ClubCode	varchar(6) NULL,
	FamilyName	varchar(48) NOT NULL,
	GivenName	varchar(48) NOT NULL,
	Gender	Gender(1) NULL,
	BirthYear	int NULL,
	PostCode	int NULL,
	PersonID	int NOT NULL,
	UNIQUE(PersonID)
)
GO

CREATE TABLE Punch (
	PunchID	int NOT NULL,
	UNIQUE(PunchID)
)
GO

CREATE TABLE Series (
	Name	varchar(40) NOT NULL,
	SeriesID	int NOT NULL,
	UNIQUE(SeriesID)
)
GO

CREATE TABLE Visit (
	PunchID	int NOT NULL,
	Time	Time NOT NULL,
	EntryID	int NULL,
	UNIQUE(PunchID, EntryID, Time)
)
GO

CREATE TABLE Entry (
	EventID	int NOT NULL,
	PersonID	int NOT NULL,
	Course	varchar(16) NOT NULL,
	Score	int NULL,
	FinishPlacing	int NULL,
	EntryID	int NOT NULL,
	UNIQUE(EntryID)
)
GO

CREATE TABLE EventScoringMethod (
	EventID	int NOT NULL,
	ScoringMethod	varchar(32) NOT NULL,
	Course	varchar(16) NOT NULL,
	UNIQUE(Course, EventID)
)
GO

CREATE TABLE EventControl (
	EventID	int NOT NULL,
	PointValue	int NULL,
	ControlNumber	int NOT NULL,
	UNIQUE(EventID, ControlNumber)
)
GO

CREATE TABLE PunchPlacement (
	PunchID	int NOT NULL,
	EventControlEventID	int NOT NULL,
	EventControlControlNumber	int NOT NULL,
	UNIQUE(PunchID, EventControlEventID, EventControlControlNumber)
)
GO

