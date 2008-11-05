CREATE TABLE Person (
	PersonID	int NOT NULL,
	Gender	Gender(1) NULL,
	GivenName	varchar(128) NULL,
	FamilyName	varchar(128) NULL,
	Occupation	varchar(128) NULL,
	Address	varchar(128) NULL,
	PreferredPicture	Picture(20) NULL,
	Email	varchar(64) NULL,
	UNIQUE(PersonID)
)
GO

CREATE TABLE Event (
	EventTypeID	int NULL,
	EventDateDay	int NULL,
	EventDateMinYear	int NULL,
	EventDateMaxYear	int NULL,
	EventDateMonth	int NULL,
	EventID	int NOT NULL,
	EventLocation	varchar(128) NULL,
	Certificate	varchar(64) NULL,
	Official	varchar(64) NULL,
	UNIQUE(EventID)
)
GO

CREATE TABLE Source (
	UserID	int NOT NULL,
	SourceName	varchar(128) NOT NULL,
	SourceID	int NOT NULL,
	UNIQUE(SourceID)
)
GO

CREATE TABLE Role (
	RoleID	int NOT NULL,
	EventRoleName	varchar NOT NULL,
	UNIQUE(RoleID)
)
GO

CREATE TABLE EventType (
	EventTypeName	varchar(16) NOT NULL,
	EventTypeID	int NOT NULL,
	UNIQUE(EventTypeID)
)
GO

CREATE TABLE User (
	Email	varchar(64) NULL,
	UserID	int NOT NULL,
	UNIQUE(UserID)
)
GO

CREATE TABLE Participation (
	PersonID	int NOT NULL,
	EventID	int NOT NULL,
	SourceID	int NOT NULL,
	RoleID	int NOT NULL,
	UNIQUE(PersonID, RoleID, EventID, SourceID)
)
GO

CREATE TABLE Friend (
	UserID	int NOT NULL,
	OtherUserID	int NOT NULL,
	IsConfirmed	bit NOT NULL,
	UNIQUE(UserID, OtherUserID)
)
GO

