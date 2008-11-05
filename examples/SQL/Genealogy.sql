CREATE TABLE Event (
	EventID	int NOT NULL,
	Certificate	varchar(64) NULL,
	EventDateDay	int NULL,
	EventDateMaxYear	int NULL,
	EventDateMinYear	int NULL,
	EventDateMonth	int NULL,
	EventLocation	varchar(128) NULL,
	EventTypeID	int NULL,
	Official	varchar(64) NULL,
	UNIQUE(EventID)
)
GO

CREATE TABLE EventType (
	EventTypeID	int NOT NULL,
	EventTypeName	varchar(16) NOT NULL,
	UNIQUE(EventTypeID)
)
GO

CREATE TABLE Friend (
	OtherUserID	int NOT NULL,
	UserID	int NOT NULL,
	IsConfirmed	bit NOT NULL,
	UNIQUE(UserID, OtherUserID)
)
GO

CREATE TABLE Participation (
	EventID	int NOT NULL,
	PersonID	int NOT NULL,
	RoleID	int NOT NULL,
	SourceID	int NOT NULL,
	UNIQUE(PersonID, RoleID, EventID, SourceID)
)
GO

CREATE TABLE Person (
	PersonID	int NOT NULL,
	Address	varchar(128) NULL,
	Email	varchar(64) NULL,
	FamilyName	varchar(128) NULL,
	Gender	FixedLengthText(1) NULL,
	GivenName	varchar(128) NULL,
	Occupation	varchar(128) NULL,
	PreferredPicture	PictureRawData(20) NULL,
	UNIQUE(PersonID)
)
GO

CREATE TABLE Role (
	RoleID	int NOT NULL,
	EventRoleName	varchar NOT NULL,
	UNIQUE(RoleID)
)
GO

CREATE TABLE Source (
	SourceID	int NOT NULL,
	SourceName	varchar(128) NOT NULL,
	UserID	int NOT NULL,
	UNIQUE(SourceID)
)
GO

CREATE TABLE User (
	UserID	int NOT NULL,
	Email	varchar(64) NULL,
	UNIQUE(UserID)
)
GO

