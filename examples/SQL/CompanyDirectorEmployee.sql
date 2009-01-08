CREATE TABLE Attendance (
	-- Attendance is where Attendee attended Meeting and Person has given-Name,
	AttendeeGivenName                       varchar(48) NOT NULL,
	-- Attendance is where Attendee attended Meeting and maybe family-Name is of Person,
	AttendeeFamilyName                      varchar(48) NULL,
	-- Attendance is where Attendee attended Meeting and Meeting is held on Date,
	MeetingDate                             datetime NOT NULL,
	-- Attendance is where Attendee attended Meeting and Meeting is board meeting,
	MeetingIsBoardMeeting                   bit NOT NULL,
	-- Attendance is where Attendee attended Meeting and Company held Meeting and Company is called CompanyName,
	MeetingCompanyName                      varchar(48) NOT NULL,
	UNIQUE(AttendeeGivenName, AttendeeFamilyName, MeetingDate, MeetingIsBoardMeeting, MeetingCompanyName)
)
GO

CREATE TABLE Company (
	-- Company is called CompanyName,
	CompanyName                             varchar(48) NOT NULL,
	-- Company is listed,
	IsListed                                bit NOT NULL,
	PRIMARY KEY(CompanyName)
)
GO

CREATE TABLE Directorship (
	-- Directorship is where Director directs Company and Person has given-Name,
	DirectorGivenName                       varchar(48) NOT NULL,
	-- Directorship is where Director directs Company and maybe family-Name is of Person,
	DirectorFamilyName                      varchar(48) NULL,
	-- Directorship is where Director directs Company and Company is called CompanyName,
	CompanyName                             varchar(48) NOT NULL,
	-- Directorship began on appointment-Date,
	AppointmentDate                         datetime NOT NULL,
	UNIQUE(DirectorGivenName, DirectorFamilyName, CompanyName),
	FOREIGN KEY (CompanyName) REFERENCES Company (CompanyName)
)
GO

CREATE TABLE Person (
	-- Person has given-Name,
	GivenName                               varchar(48) NOT NULL,
	-- maybe Person was born on birth-Date,
	BirthDate                               datetime NULL CHECK(BirthDate >= '1900/01/01'),
	-- maybe family-Name is of Person,
	FamilyName                              varchar(48) NULL,
	-- maybe Employee is a subtype of Person and Employee has EmployeeNr,
	EmployeeNr                              int NULL,
	-- maybe Employee is a subtype of Person and Employee works at Company and Company is called CompanyName,
	EmployeeCompanyName                     varchar(48) NULL,
	-- maybe Employee is a subtype of Person and maybe Employee is supervised by Manager and Employee has EmployeeNr,
	EmployeeManagerNr                       int NULL,
	-- maybe Employee is a subtype of Person and maybe Manager is a subtype of Employee and Manager is ceo,
	ManagerIsCeo                            bit NULL,
	UNIQUE(GivenName, FamilyName),
	FOREIGN KEY (EmployeeCompanyName) REFERENCES Company (CompanyName)
)
GO

ALTER TABLE Attendance
	ADD FOREIGN KEY (AttendeeGivenName, AttendeeFamilyName) REFERENCES Person (GivenName, FamilyName)
GO

ALTER TABLE Directorship
	ADD FOREIGN KEY (DirectorGivenName, DirectorFamilyName) REFERENCES Person (GivenName, FamilyName)
GO

ALTER TABLE Person
	ADD FOREIGN KEY (EmployeeManagerNr) REFERENCES Person (EmployeeNr)
GO

