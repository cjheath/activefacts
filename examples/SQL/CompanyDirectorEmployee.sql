CREATE TABLE Person (
	EmployeeCompanyName	varchar(48) NULL,
	ManagerIsCeo	bit NULL,
	EmployeeManagerNr	int NULL,
	EmployeeNr	int NULL,
	GivenName	varchar(48) NOT NULL,
	FamilyName	varchar(48) NULL,
	BirthDate	datetime NULL,
	UNIQUE(GivenName, FamilyName)
)
GO

CREATE TABLE Company (
	IsListed	bit NOT NULL,
	CompanyName	varchar(48) NOT NULL,
	UNIQUE(CompanyName)
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

CREATE TABLE Attendance (
	AttendeeGivenName	varchar(48) NOT NULL,
	AttendeeFamilyName	varchar(48) NULL,
	MeetingCompanyName	varchar(48) NOT NULL,
	MeetingIsBoardMeeting	bit NOT NULL,
	MeetingDate	datetime NOT NULL,
	UNIQUE(AttendeeGivenName, AttendeeFamilyName, MeetingDate, MeetingIsBoardMeeting, MeetingCompanyName)
)
GO

