CREATE TABLE Event (
	-- Event has EventID,
	EventID                                 int IDENTITY NOT NULL,
	-- maybe Event occurred at EventLocation,
	EventLocation                           varchar(128) NULL,
	-- maybe Event is certified by Certificate,
	Certificate                             varchar(64) NULL,
	-- maybe Event was confirmed by Official,
	Official                                varchar(64) NULL,
	-- maybe Event is of EventType and EventType has EventTypeID,
	EventTypeID                             int NULL,
	-- maybe Event occurred on EventDate and maybe EventDate occurred on Day,
	EventDateDay                            int NULL CHECK((EventDateDay >= 1 AND EventDateDay <= 31)),
	-- maybe Event occurred on EventDate and maybe EventDate wasnt before min-Year,
	EventDateMinYear                        int NULL,
	-- maybe Event occurred on EventDate and maybe EventDate wasnt after max-Year,
	EventDateMaxYear                        int NULL,
	-- maybe Event occurred on EventDate and maybe EventDate occurred in Month,
	EventDateMonth                          int NULL CHECK((EventDateMonth >= 1 AND EventDateMonth <= 12)),
	PRIMARY KEY(EventID)
)
GO

CREATE TABLE EventType (
	-- EventType is called EventTypeName,
	EventTypeName                           varchar(16) NOT NULL CHECK(EventTypeName = 'Birth' OR EventTypeName = 'Christening' OR EventTypeName = 'Marriage' OR EventTypeName = 'Divorce' OR EventTypeName = 'Death' OR EventTypeName = 'Burial'),
	-- EventType has EventTypeID,
	EventTypeID                             int IDENTITY NOT NULL,
	PRIMARY KEY(EventTypeID),
	UNIQUE(EventTypeName)
)
GO

CREATE TABLE Friend (
	-- Friend is where User is friend of other-User and User has UserID,
	UserID                                  int NOT NULL,
	-- Friend is where User is friend of other-User and User has UserID,
	OtherUserID                             int NOT NULL,
	-- Friend is confirmed,
	IsConfirmed                             bit NOT NULL,
	PRIMARY KEY(UserID, OtherUserID)
)
GO

CREATE TABLE Participation (
	-- Participation is where Person played Role in Event according to Source and Person has PersonID,
	PersonID                                int NOT NULL,
	-- Participation is where Person played Role in Event according to Source and Role has RoleID,
	RoleID                                  int NOT NULL,
	-- Participation is where Person played Role in Event according to Source and Event has EventID,
	EventID                                 int NOT NULL,
	-- Participation is where Person played Role in Event according to Source and Source has SourceID,
	SourceID                                int NOT NULL,
	PRIMARY KEY(PersonID, RoleID, EventID, SourceID),
	FOREIGN KEY (EventID) REFERENCES Event (EventID)
)
GO

CREATE TABLE Person (
	-- Person has PersonID,
	PersonID                                int IDENTITY NOT NULL,
	-- maybe Person is of Gender,
	Gender                                  char(1) NULL CHECK(Gender = 'M' OR Gender = 'F'),
	-- maybe given-Name is name of Person,
	GivenName                               varchar(128) NULL,
	-- maybe Person is called family-Name,
	FamilyName                              varchar(128) NULL,
	-- maybe Occupation is of Person,
	Occupation                              varchar(128) NULL,
	-- maybe Address is of Person,
	Address                                 varchar(128) NULL,
	-- maybe preferred-Picture is of Person,
	PreferredPicture                        image(20) NULL,
	-- maybe Email is of Person,
	Email                                   varchar(64) NULL,
	PRIMARY KEY(PersonID)
)
GO

CREATE TABLE Role (
	-- Role has RoleID,
	RoleID                                  int IDENTITY NOT NULL,
	-- Role is called EventRoleName,
	EventRoleName                           varchar NOT NULL CHECK(EventRoleName = 'Subject' OR EventRoleName = 'Father' OR EventRoleName = 'Mother' OR EventRoleName = 'Husband' OR EventRoleName = 'Wife' OR EventRoleName = 'Celebrant'),
	PRIMARY KEY(RoleID),
	UNIQUE(EventRoleName)
)
GO

CREATE TABLE Source (
	-- Source has SourceName,
	SourceName                              varchar(128) NOT NULL,
	-- Source has SourceID,
	SourceID                                int IDENTITY NOT NULL,
	-- User provided Source and User has UserID,
	UserID                                  int NOT NULL,
	PRIMARY KEY(SourceID),
	UNIQUE(SourceName)
)
GO

CREATE TABLE [User] (
	-- User has UserID,
	UserID                                  int IDENTITY NOT NULL,
	-- maybe Email is of User,
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

