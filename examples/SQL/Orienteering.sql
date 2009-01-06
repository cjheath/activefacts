CREATE TABLE Club (
	ClubName                                VariableLengthText(32) NOT NULL,
	ClubCode                                VariableLengthText(6) NOT NULL,
	PRIMARY KEY(ClubCode)
)
GO

CREATE TABLE Entry (
	PersonID                                AutoCounter NOT NULL,
	Course                                  VariableLengthText(16) NOT NULL CHECK(REVISIT: valid value),
	EventID                                 AutoCounter NOT NULL,
	Score                                   SignedInteger(32) NULL,
	FinishPlacing                           UnsignedInteger(32) NULL,
	EntryID                                 AutoCounter NOT NULL,
	PRIMARY KEY(EntryID)
)
GO

CREATE TABLE Event (
	EventName                               VariableLengthText(50) NULL,
	MapID                                   AutoCounter NOT NULL,
	StartLocation                           VariableLengthText(200) NOT NULL,
	EventID                                 AutoCounter NOT NULL,
	StartTime                               DateAndTime NOT NULL,
	SeriesID                                AutoCounter NULL,
	Number                                  UnsignedInteger(32) NULL CHECK(REVISIT: valid value),
	ClubCode                                VariableLengthText(6) NOT NULL,
	PRIMARY KEY(EventID)
)
GO

CREATE TABLE EventControl (
	EventID                                 AutoCounter NOT NULL,
	ControlNumber                           UnsignedInteger(32) NOT NULL CHECK(REVISIT: valid value),
	PointValue                              UnsignedInteger(32) NULL,
	PRIMARY KEY(EventID, ControlNumber)
)
GO

CREATE TABLE EventScoringMethod (
	ScoringMethod                           VariableLengthText(32) NOT NULL CHECK(REVISIT: valid value),
	Course                                  VariableLengthText(16) NOT NULL CHECK(REVISIT: valid value),
	EventID                                 AutoCounter NOT NULL,
	PRIMARY KEY(Course, EventID)
)
GO

CREATE TABLE Map (
	MapName                                 VariableLengthText(80) NOT NULL,
	OwnerCode                               VariableLengthText(6) NOT NULL,
	Accessibility                           FixedLengthText(1) NULL CHECK(REVISIT: valid value),
	MapID                                   AutoCounter NOT NULL,
	PRIMARY KEY(MapID)
)
GO

CREATE TABLE Person (
	FamilyName                              VariableLengthText(48) NOT NULL,
	GivenName                               VariableLengthText(48) NOT NULL,
	Gender                                  FixedLengthText(1) NULL CHECK(REVISIT: valid value),
	BirthYear                               UnsignedInteger(32) NULL CHECK(REVISIT: valid value),
	PostCode                                UnsignedInteger(32) NULL,
	ClubCode                                VariableLengthText(6) NULL,
	PersonID                                AutoCounter NOT NULL,
	PRIMARY KEY(PersonID)
)
GO

CREATE TABLE Punch (
	PunchID                                 AutoCounter NOT NULL,
	PRIMARY KEY(PunchID)
)
GO

CREATE TABLE PunchPlacement (
	PunchID                                 AutoCounter NOT NULL,
	EventControlEventID                     AutoCounter NOT NULL,
	EventControlControlNumber               UnsignedInteger(32) NOT NULL CHECK(REVISIT: valid value),
	PRIMARY KEY(PunchID, EventControlEventID, EventControlControlNumber)
)
GO

CREATE TABLE Series (
	Name                                    VariableLengthText(40) NOT NULL,
	SeriesID                                AutoCounter NOT NULL,
	PRIMARY KEY(SeriesID)
)
GO

CREATE TABLE Visit (
	PunchID                                 AutoCounter NOT NULL,
	EntryID                                 AutoCounter NOT NULL,
	Time                                    DateAndTime NOT NULL,
	PRIMARY KEY(PunchID, EntryID, Time)
)
GO

