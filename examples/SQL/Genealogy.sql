CREATE TABLE Event (
	EventID                                 AutoCounter NOT NULL,
	EventLocation                           VariableLengthText(128) NULL,
	Certificate                             VariableLengthText(64) NULL,
	Official                                VariableLengthText(64) NULL,
	EventTypeID                             AutoCounter NULL,
	EventDateDay                            UnsignedInteger(32) NULL CHECK(REVISIT: valid value),
	EventDateMinYear                        UnsignedInteger(32) NULL,
	EventDateMaxYear                        UnsignedInteger(32) NULL,
	EventDateMonth                          UnsignedInteger(32) NULL CHECK(REVISIT: valid value),
	PRIMARY KEY(EventID)
)
GO

CREATE TABLE EventType (
	EventTypeName                           VariableLengthText(16) NOT NULL CHECK(REVISIT: valid value),
	EventTypeID                             AutoCounter NOT NULL,
	PRIMARY KEY(EventTypeID)
)
GO

CREATE TABLE Friend (
	UserID                                  AutoCounter NOT NULL,
	OtherUserID                             AutoCounter NOT NULL,
	IsConfirmed                             BIT NOT NULL,
	PRIMARY KEY(UserID, OtherUserID)
)
GO

CREATE TABLE Participation (
	PersonID                                AutoCounter NOT NULL,
	RoleID                                  AutoCounter NOT NULL,
	EventID                                 AutoCounter NOT NULL,
	SourceID                                AutoCounter NOT NULL,
	PRIMARY KEY(PersonID, RoleID, EventID, SourceID)
)
GO

CREATE TABLE Person (
	PersonID                                AutoCounter NOT NULL,
	Gender                                  FixedLengthText(1) NULL CHECK(REVISIT: valid value),
	GivenName                               VariableLengthText(128) NULL,
	FamilyName                              VariableLengthText(128) NULL,
	Occupation                              VariableLengthText(128) NULL,
	Address                                 VariableLengthText(128) NULL,
	PreferredPicture                        PictureRawData(20) NULL,
	Email                                   VariableLengthText(64) NULL,
	PRIMARY KEY(PersonID)
)
GO

CREATE TABLE Role (
	RoleID                                  AutoCounter NOT NULL,
	EventRoleName                           VariableLengthText NOT NULL CHECK(REVISIT: valid value),
	PRIMARY KEY(RoleID)
)
GO

CREATE TABLE Source (
	SourceName                              VariableLengthText(128) NOT NULL,
	SourceID                                AutoCounter NOT NULL,
	UserID                                  AutoCounter NOT NULL,
	PRIMARY KEY(SourceID)
)
GO

CREATE TABLE [User] (
	UserID                                  AutoCounter NOT NULL,
	Email                                   VariableLengthText(64) NULL,
	PRIMARY KEY(UserID)
)
GO

