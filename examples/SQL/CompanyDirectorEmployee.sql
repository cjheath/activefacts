CREATE TABLE Attendance (
	AttendeeGivenName                       varchar(48) NOT NULL,
	AttendeeFamilyName                      varchar(48) NULL,
	MeetingDate                             datetime NOT NULL,
	MeetingIsBoardMeeting                   bit NOT NULL,
	MeetingCompanyName                      varchar(48) NOT NULL,
	UNIQUE(AttendeeGivenName, AttendeeFamilyName, MeetingDate, MeetingIsBoardMeeting, MeetingCompanyName)
)
GO

CREATE TABLE Company (
	CompanyName                             varchar(48) NOT NULL,
	IsListed                                bit NOT NULL,
	PRIMARY KEY(CompanyName)
)
GO

CREATE TABLE Directorship (
	DirectorGivenName                       varchar(48) NOT NULL,
	DirectorFamilyName                      varchar(48) NULL,
	CompanyName                             varchar(48) NOT NULL,
	AppointmentDate                         datetime NOT NULL,
	UNIQUE(DirectorGivenName, DirectorFamilyName, CompanyName),
	FOREIGN KEY (CompanyName) REFERENCES Company (CompanyName)
)
GO

CREATE TABLE Person (
	GivenName                               varchar(48) NOT NULL,
	BirthDate                               datetime NULL CHECK(BirthDate >= '1900/01/01'),
	FamilyName                              varchar(48) NULL,
	EmployeeNr                              int NULL,
	EmployeeCompanyName                     varchar(48) NULL,
	EmployeeManagerNr                       int NULL,
	ManagerIsCeo                            bit NULL,
	UNIQUE(GivenName, FamilyName)
)
GO

ALTER TABLE Attendance
	ADD FOREIGN KEY (AttendeeGivenName, AttendeeFamilyName) REFERENCES Person (GivenName, FamilyName)
GO

ALTER TABLE Directorship
	ADD FOREIGN KEY (DirectorGivenName, DirectorFamilyName) REFERENCES Person (GivenName, FamilyName)
GO

