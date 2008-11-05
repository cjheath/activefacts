CREATE TABLE Person (
	GivenName	varchar(48) NOT NULL,
	FamilyName	varchar(48) NULL,
	BirthDate	datetime NULL,
	UNIQUE(FamilyName, GivenName)
)
GO

CREATE TABLE Meeting (
	CompanyName	varchar NOT NULL,
	IsBoardMeeting	bit NOT NULL,
	Date	datetime NOT NULL,
	UNIQUE(Date, CompanyName)
)
GO

CREATE TABLE Directorship (
	DirectorFamilyName	varchar(48) NULL,
	DirectorGivenName	varchar(48) NOT NULL,
	CompanyName	varchar NOT NULL,
	AppointmentDate	datetime NOT NULL,
	UNIQUE(DirectorFamilyName, DirectorGivenName, CompanyName)
)
GO

CREATE TABLE Attendance (
	AttendeeFamilyName	varchar(48) NULL,
	AttendeeGivenName	varchar(48) NOT NULL,
	MeetingDate	datetime NOT NULL,
	MeetingCompanyName	varchar NOT NULL,
	UNIQUE(AttendeeFamilyName, AttendeeGivenName, MeetingDate, MeetingCompanyName)
)
GO

