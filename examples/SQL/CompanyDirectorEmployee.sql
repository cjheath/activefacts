CREATE TABLE Attendance (
	-- Attendance is where Person attended Meeting and maybe family-Name is of Person,
	AttendeeFamilyName                      varchar(48) NULL,
	-- Attendance is where Person attended Meeting and Person has given-Name,
	AttendeeGivenName                       varchar(48) NOT NULL,
	-- Attendance is where Person attended Meeting and Meeting is held by Company and Company is called Company Name,
	MeetingCompanyName                      varchar(48) NOT NULL,
	-- Attendance is where Person attended Meeting and Meeting is held on Date,
	MeetingDate                             datetime NOT NULL,
	-- Attendance is where Person attended Meeting and Meeting is board meeting,
	MeetingIsBoardMeeting                   bit NULL,
	UNIQUE(AttendeeGivenName, AttendeeFamilyName, MeetingCompanyName, MeetingDate, MeetingIsBoardMeeting)
)
GO

CREATE TABLE Company (
	-- Company is called Company Name,
	CompanyName                             varchar(48) NOT NULL,
	-- Company is listed,
	IsListed                                bit NULL,
	PRIMARY KEY(CompanyName)
)
GO

CREATE TABLE Directorship (
	-- Directorship began on appointment-Date,
	AppointmentDate                         datetime NOT NULL,
	-- Directorship is where Person directs Company and Company is called Company Name,
	CompanyName                             varchar(48) NOT NULL,
	-- Directorship is where Person directs Company and maybe family-Name is of Person,
	DirectorFamilyName                      varchar(48) NULL,
	-- Directorship is where Person directs Company and Person has given-Name,
	DirectorGivenName                       varchar(48) NOT NULL,
	UNIQUE(DirectorGivenName, DirectorFamilyName, CompanyName),
	FOREIGN KEY (CompanyName) REFERENCES Company (CompanyName)
)
GO

CREATE TABLE Meeting (
	-- Meeting is held by Company and Company is called Company Name,
	CompanyName                             varchar(48) NOT NULL,
	-- Meeting is held on Date,
	Date                                    datetime NOT NULL,
	-- Meeting is board meeting,
	IsBoardMeeting                          bit NULL,
	UNIQUE(CompanyName, Date, IsBoardMeeting),
	FOREIGN KEY (CompanyName) REFERENCES Company (CompanyName)
)
GO

CREATE TABLE Person (
	-- maybe Person was born on birth-Date,
	BirthDate                               datetime NULL CHECK(BirthDate >= '1900/01/01'),
	-- maybe Employee is a kind of Person and Employee works at Company and Company is called Company Name,
	EmployeeCompanyName                     varchar(48) NULL,
	-- maybe Employee is a kind of Person and maybe Employee is supervised by Manager and Employee has Employee Nr,
	EmployeeManagerNr                       int NULL,
	-- maybe Employee is a kind of Person and Employee has Employee Nr,
	EmployeeNr                              int NULL,
	-- maybe family-Name is of Person,
	FamilyName                              varchar(48) NULL,
	-- Person has given-Name,
	GivenName                               varchar(48) NOT NULL,
	-- maybe Employee is a kind of Person and maybe Manager is a kind of Employee and Manager is ceo,
	ManagerIsCeo                            bit NULL,
	UNIQUE(GivenName, FamilyName),
	FOREIGN KEY (EmployeeCompanyName) REFERENCES Company (CompanyName),
	FOREIGN KEY (EmployeeManagerNr) REFERENCES Person (GivenName)
)
GO

CREATE VIEW dbo.EmployeeInPerson_Nr (EmployeeNr) WITH SCHEMABINDING AS
	SELECT EmployeeNr FROM dbo.Person
	WHERE	EmployeeNr IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX PK_EmployeeInPerson ON dbo.EmployeeInPerson_Nr(EmployeeNr)
GO

ALTER TABLE Attendance
	ADD FOREIGN KEY (MeetingCompanyName, MeetingDate, MeetingIsBoardMeeting) REFERENCES Meeting (CompanyName, Date, IsBoardMeeting)
GO

ALTER TABLE Attendance
	ADD FOREIGN KEY (AttendeeGivenName, AttendeeFamilyName) REFERENCES Person (GivenName, FamilyName)
GO

ALTER TABLE Directorship
	ADD FOREIGN KEY (DirectorGivenName, DirectorFamilyName) REFERENCES Person (GivenName, FamilyName)
GO

