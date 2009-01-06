CREATE TABLE Event (
	EventID                                 int IDENTITY NOT NULL,
	EventLocation                           varchar(128) NULL,
	Certificate                             varchar(64) NULL,
	Official                                varchar(64) NULL,
	EventTypeID                             int NULL,
	EventDateDay                            int NULL CHECK((EventDateDay >= 1 AND EventDateDay <= 31)),
	EventDateMinYear                        int NULL,
	EventDateMaxYear                        int NULL,
	EventDateMonth                          int NULL CHECK((EventDateMonth >= 1 AND EventDateMonth <= 12)),
	PRIMARY KEY(EventID)
)
GO

CREATE TABLE EventType (
	EventTypeName                           varchar(16) NOT NULL CHECK(EventTypeName = 'Birth' OR EventTypeName = 'Christening' OR EventTypeName = 'Marriage' OR EventTypeName = 'Divorce' OR EventTypeName = 'Death' OR EventTypeName = 'Burial'),
	EventTypeID                             int IDENTITY NOT NULL,
	PRIMARY KEY(EventTypeID)
)
GO

CREATE TABLE Friend (
	UserID                                  int NOT NULL,
	OtherUserID                             int NOT NULL,
	IsConfirmed                             bit NOT NULL,
	PRIMARY KEY(UserID, OtherUserID)
)
GO

CREATE TABLE Participation (
	PersonID                                int NOT NULL,
	RoleID                                  int NOT NULL,
	EventID                                 int NOT NULL,
	SourceID                                int NOT NULL,
	PRIMARY KEY(PersonID, RoleID, EventID, SourceID),
	FOREIGN KEY (EventID) REFERENCES Event (EventID)
)
GO

CREATE TABLE Person (
	PersonID                                int IDENTITY NOT NULL,
	Gender                                  char(1) NULL CHECK(Gender = 'M' OR Gender = 'F'),
	GivenName                               varchar(128) NULL,
	FamilyName                              varchar(128) NULL,
	Occupation                              varchar(128) NULL,
	Address                                 varchar(128) NULL,
	PreferredPicture                        image(20) NULL,
	Email                                   varchar(64) NULL,
	PRIMARY KEY(PersonID)
)
GO

CREATE TABLE Role (
	RoleID                                  int IDENTITY NOT NULL,
	EventRoleName                           varchar NOT NULL CHECK(EventRoleName = 'Subject' OR EventRoleName = 'Father' OR EventRoleName = 'Mother' OR EventRoleName = 'Husband' OR EventRoleName = 'Wife' OR EventRoleName = 'Celebrant'),
	PRIMARY KEY(RoleID)
)
GO

CREATE TABLE Source (
	SourceName                              varchar(128) NOT NULL,
	SourceID                                int IDENTITY NOT NULL,
	UserID                                  int NOT NULL,
	PRIMARY KEY(SourceID)
)
GO

CREATE TABLE [User] (
	UserID                                  int IDENTITY NOT NULL,
	Email                                   varchar(64) NULL,
	PRIMARY KEY(UserID)
)
GO

ALTER TABLE Event
	ADD FOREIGN KEY (EventTypeID) REFERENCES EventType (EventTypeID)
GO

ALTER TABLE Friend
	ADD FOREIGN KEY (UserID) REFERENCES [User] (UserID)
GO

ALTER TABLE Friend
	ADD FOREIGN KEY (OtherUserID) REFERENCES [User] (UserID)
GO

ALTER TABLE Participation
	ADD FOREIGN KEY (PersonID) REFERENCES Person (PersonID)
GO

ALTER TABLE Participation
	ADD FOREIGN KEY (RoleID) REFERENCES Role (RoleID)
GO

ALTER TABLE Participation
	ADD FOREIGN KEY (SourceID) REFERENCES Source (SourceID)
GO

ALTER TABLE Source
	ADD FOREIGN KEY (UserID) REFERENCES [User] (UserID)
GO

