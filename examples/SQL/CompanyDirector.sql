CREATE TABLE Attendance (
	AttendeeFamilyName	varchar(48) NULL,
	AttendeeGivenName	varchar(48) NOT NULL,
	MeetingCompanyName	varchar(48) NOT NULL,
	MeetingDate	datetime NOT NULL,
	UNIQUE(AttendeeGivenName, AttendeeFamilyName, MeetingCompanyName, MeetingDate)
)
GO

CREATE TABLE Directorship (
	CompanyName	varchar(48) NOT NULL,
	DirectorFamilyName	varchar(48) NULL,
	DirectorGivenName	varchar(48) NOT NULL,
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

CREATE TABLE Person (
	FamilyName	varchar(48) NULL,
	GivenName	varchar(48) NOT NULL,
	BirthDate	datetime NULL,
	UNIQUE(GivenName, FamilyName)
)
GO

