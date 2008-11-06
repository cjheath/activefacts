CREATE TABLE Attendance (
	AttendeeFamilyName	varchar(48) NULL,
	AttendeeGivenName	varchar(48) NOT NULL,
	MeetingCompanyName	varchar NOT NULL,
	MeetingDate	datetime NOT NULL,
	UNIQUE(AttendeeFamilyName, AttendeeGivenName, MeetingDate, MeetingCompanyName)
)
GO

CREATE TABLE Directorship (
	CompanyName	varchar NOT NULL,
	DirectorFamilyName	varchar(48) NULL,
	DirectorGivenName	varchar(48) NOT NULL,
	AppointmentDate	datetime NOT NULL,
	UNIQUE(DirectorFamilyName, DirectorGivenName, CompanyName)
)
GO

CREATE TABLE Meeting (
	CompanyName	varchar NOT NULL,
	Date	datetime NOT NULL,
	IsBoardMeeting	bit NOT NULL,
	UNIQUE(Date, CompanyName)
)
GO

CREATE TABLE Person (
	FamilyName	varchar(48) NULL,
	GivenName	varchar(48) NOT NULL,
	BirthDate	datetime NULL,
	UNIQUE(FamilyName, GivenName)
)
GO

ALTER TABLE Attendance
	ADD FOREIGN KEY(AttendeeFamilyName, AttendeeGivenName)
	REFERENCES Person(FamilyName, GivenName)
GO

ALTER TABLE Attendance
	ADD FOREIGN KEY(MeetingDate, MeetingCompanyName)
	REFERENCES Meeting(Date, CompanyName)
GO

ALTER TABLE Directorship
	ADD FOREIGN KEY(DirectorFamilyName, DirectorGivenName)
	REFERENCES Person(FamilyName, GivenName)
GO

