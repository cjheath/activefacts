CREATE TABLE Event (
	-- maybe Event is certified by Certificate,
	Certificate                             varchar(64) NULL,
	-- maybe Event occurred on Event Date and maybe Event Date occurred on Day,
	EventDateDay                            int NULL CHECK((EventDateDay >= 1 AND EventDateDay <= 31)),
	-- maybe Event occurred on Event Date and maybe Event Date wasnt after max-Year,
	EventDateMaxYear                        int NULL,
	-- maybe Event occurred on Event Date and maybe Event Date wasnt before min-Year,
	EventDateMinYear                        int NULL,
	-- maybe Event occurred on Event Date and maybe Event Date occurred in Month,
	EventDateMonth                          int NULL CHECK((EventDateMonth >= 1 AND EventDateMonth <= 12)),
	-- Event has Event ID,
	EventID                                 int IDENTITY NOT NULL,
	-- maybe Event occurred at Event Location,
	EventLocation                           varchar(128) NULL,
	-- maybe Event is of Event Type and Event Type has Event Type ID,
	EventTypeID                             int NULL,
	-- maybe Event was confirmed by Official,
	Official                                varchar(64) NULL,
	PRIMARY KEY(EventID)
)
GO

CREATE TABLE EventType (
	-- Event Type has Event Type ID,
	EventTypeID                             int IDENTITY NOT NULL,
	-- Event Type is called Event Type Name,
	EventTypeName                           varchar(16) NOT NULL CHECK(EventTypeName = 'Birth' OR EventTypeName = 'Burial' OR EventTypeName = 'Christening' OR EventTypeName = 'Death' OR EventTypeName = 'Divorce' OR EventTypeName = 'Marriage'),
	PRIMARY KEY(EventTypeID),
	UNIQUE(EventTypeName)
)
GO

CREATE TABLE Friendship (
	-- Friendship is confirmed,
	IsConfirmed                             bit NULL,
	-- Friendship is where User is friendly with other-User and User has User ID,
	OtherUserID                             int NOT NULL,
	-- Friendship is where User is friendly with other-User and User has User ID,
	UserID                                  int NOT NULL,
	PRIMARY KEY(UserID, OtherUserID)
)
GO

CREATE TABLE Participation (
	-- Participation is where Person played Role in Event according to Source and Event has Event ID,
	EventID                                 int NOT NULL,
	-- Participation is where Person played Role in Event according to Source and Person has Person ID,
	PersonID                                int NOT NULL,
	-- Participation is where Person played Role in Event according to Source and Role has Role ID,
	RoleID                                  int NOT NULL,
	-- Participation is where Person played Role in Event according to Source and Source has Source ID,
	SourceID                                int NOT NULL,
	PRIMARY KEY(PersonID, RoleID, EventID, SourceID),
	FOREIGN KEY (EventID) REFERENCES Event (EventID)
)
GO

CREATE TABLE Person (
	-- maybe Address is of Person,
	Address                                 varchar(128) NULL,
	-- maybe Email is of Person,
	Email                                   varchar(64) NULL,
	-- maybe Person is called family-Name,
	FamilyName                              varchar(128) NULL,
	-- maybe Person is of Gender,
	Gender                                  char(1) NULL CHECK(Gender = 'F' OR Gender = 'M'),
	-- maybe given-Name is name of Person,
	GivenName                               varchar(128) NULL,
	-- maybe Occupation is of Person,
	Occupation                              varchar(128) NULL,
	-- Person has Person ID,
	PersonID                                int IDENTITY NOT NULL,
	-- maybe preferred-Picture is of Person,
	PreferredPicture                        image NULL,
	PRIMARY KEY(PersonID)
)
GO

CREATE TABLE Role (
	-- Role is called Event Role Name,
	EventRoleName                           varchar NOT NULL CHECK(EventRoleName = 'Celebrant' OR EventRoleName = 'Father' OR EventRoleName = 'Husband' OR EventRoleName = 'Mother' OR EventRoleName = 'Subject' OR EventRoleName = 'Wife'),
	-- Role has Role ID,
	RoleID                                  int IDENTITY NOT NULL,
	PRIMARY KEY(RoleID),
	UNIQUE(EventRoleName)
)
GO

CREATE TABLE Source (
	-- Source has Source ID,
	SourceID                                int IDENTITY NOT NULL,
	-- Source has Source Name,
	SourceName                              varchar(128) NOT NULL,
	-- User provided Source and User has User ID,
	UserID                                  int NOT NULL,
	PRIMARY KEY(SourceID),
	UNIQUE(SourceName)
)
GO

CREATE TABLE [User] (
	-- maybe Email is of User,
	Email                                   varchar(64) NULL,
	-- User has User ID,
	UserID                                  int IDENTITY NOT NULL,
	PRIMARY KEY(UserID)
)
GO

ALTER TABLE Event
	ADD FOREIGN KEY (EventTypeID) REFERENCES EventType (EventTypeID)
GO

ALTER TABLE Friendship
	ADD FOREIGN KEY (OtherUserID) REFERENCES [User] (UserID)
GO

ALTER TABLE Friendship
	ADD FOREIGN KEY (UserID) REFERENCES [User] (UserID)
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

