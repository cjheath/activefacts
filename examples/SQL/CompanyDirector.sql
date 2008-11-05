CREATE TABLE Person (
	GivenName	varchar(48) NOT NULL,
	FamilyName	varchar(48) NULL,
	BirthDate	datetime NULL,
	UNIQUE(GivenName, FamilyName)
)
GO

CREATE TABLE Directorship (
	DirectorGivenName	varchar(48) NOT NULL,
	DirectorFamilyName	varchar(48) NULL,
	CompanyName	varchar(48) NOT NULL,
	AppointmentDate	datetime NOT NULL,
	UNIQUE(DirectorGivenName, DirectorFamilyName, CompanyName)
)
GO

CREATE TABLE Meeting (
	CompanyName	varchar(48) NOT NULL,
	Date	datetime NOT NULL,
	IsBoardMeeting	bit NOT NULL,
	UNIQUE(CompanyName, Date)
)
GO

CREATE TABLE Attendance (
	AttendeeGivenName	varchar(48) NOT NULL,
	AttendeeFamilyName	varchar(48) NULL,
	MeetingCompanyName	varchar(48) NOT NULL,
	MeetingDate	datetime NOT NULL,
	UNIQUE(AttendeeGivenName, AttendeeFamilyName, MeetingCompanyName, MeetingDate)
)
GO

