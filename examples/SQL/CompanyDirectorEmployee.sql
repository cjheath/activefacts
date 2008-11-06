CREATE TABLE Attendance (
	AttendeeFamilyName	varchar(48) NULL,
	AttendeeGivenName	varchar(48) NOT NULL,
	MeetingCompanyName	varchar(48) NOT NULL,
	MeetingDate	datetime NOT NULL,
	MeetingIsBoardMeeting	bit NOT NULL,
	UNIQUE(AttendeeGivenName, AttendeeFamilyName, MeetingDate, MeetingIsBoardMeeting, MeetingCompanyName)
)
GO

CREATE TABLE Company (
	CompanyName	varchar(48) NOT NULL,
	IsListed	bit NOT NULL,
	UNIQUE(CompanyName)
)
GO

CREATE TABLE Directorship (
	CompanyName	varchar(48) NOT NULL,
	DirectorFamilyName	varchar(48) NULL,
	DirectorGivenName	varchar(48) NOT NULL,
	AppointmentDate	datetime NOT NULL,
	UNIQUE(DirectorGivenName, DirectorFamilyName, CompanyName),
	FOREIGN KEY(CompanyName)
	REFERENCES Company(CompanyName)
)
GO

CREATE TABLE Person (
	FamilyName	varchar(48) NULL,
	GivenName	varchar(48) NOT NULL,
	BirthDate	datetime NULL,
	EmployeeCompanyName	varchar(48) NULL,
	EmployeeManagerNr	int NULL,
	EmployeeNr	int NULL,
	ManagerIsCeo	bit NULL,
	UNIQUE(GivenName, FamilyName)
)
GO

ALTER TABLE Attendance
	ADD FOREIGN KEY(AttendeeGivenName, AttendeeFamilyName)
	REFERENCES Person(GivenName, FamilyName)
GO

ALTER TABLE Directorship
	ADD FOREIGN KEY(DirectorGivenName, DirectorFamilyName)
	REFERENCES Person(GivenName, FamilyName)
GO

