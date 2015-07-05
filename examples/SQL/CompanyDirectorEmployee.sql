CREATE TABLE Attendance (
	-- Attendance involves Person and maybe Person is called family-Name,
	AttendeeFamilyName                      varchar(48) NULL,
	-- Attendance involves Person and Person has given-Name,
	AttendeeGivenName                       varchar(48) NOT NULL,
	-- Attendance involves Meeting and Meeting is held by Company and Company is called Company Name,
	MeetingCompanyName                      varchar(48) NOT NULL,
	-- Attendance involves Meeting and Meeting is held on Date,
	MeetingDate                             datetime NOT NULL,
	-- Attendance involves Meeting and Meeting is board meeting,
	MeetingIsBoardMeeting                   bit NULL,
	UNIQUE(AttendeeGivenName, AttendeeFamilyName, MeetingCompanyName, MeetingDate, MeetingIsBoardMeeting)
)
GO

CREATE TABLE Company (
	-- Company is called Company Name,
	CompanyName                             varchar(48) NOT NULL,
	-- Company is listed Boolean,
	IsListed                                bit NULL,
	PRIMARY KEY(CompanyName)
)
GO

CREATE TABLE Directorship (
	-- Directorship began on appointment-Date,
	AppointmentDate                         datetime NOT NULL,
	-- Directorship involves Company and Company is called Company Name,
	CompanyName                             varchar(48) NOT NULL,
	-- Directorship involves Person and maybe Person is called family-Name,
	DirectorFamilyName                      varchar(48) NULL,
	-- Directorship involves Person and Person has given-Name,
	DirectorGivenName                       varchar(48) NOT NULL,
	UNIQUE(DirectorGivenName, DirectorFamilyName, CompanyName),
	FOREIGN KEY (CompanyName) REFERENCES Company (CompanyName)
)
GO

CREATE TABLE Employee (
	-- Employee works at Company and Company is called Company Name,
	CompanyName                             varchar(48) NOT NULL,
	-- Employee has Employee Nr,
	EmployeeNr                              int NOT NULL,
	-- maybe Employee is a Manager and Manager is ceo Boolean,
	ManagerIsCeo                            bit NULL,
	-- maybe Employee is supervised by Manager and Manager is a kind of Employee and Employee has Employee Nr,
	ManagerNr                               int NULL,
	PRIMARY KEY(EmployeeNr),
	FOREIGN KEY (CompanyName) REFERENCES Company (CompanyName),
	FOREIGN KEY (ManagerNr) REFERENCES Employee (EmployeeNr)
)
GO

CREATE TABLE Employment (
	-- Employment involves Employee and Employee has Employee Nr,
	EmployeeNr                              int NOT NULL,
	-- Employment involves Person and maybe Person is called family-Name,
	PersonFamilyName                        varchar(48) NULL,
	-- Employment involves Person and Person has given-Name,
	PersonGivenName                         varchar(48) NOT NULL,
	UNIQUE(PersonGivenName, PersonFamilyName, EmployeeNr),
	FOREIGN KEY (EmployeeNr) REFERENCES Employee (EmployeeNr)
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
	-- maybe Person is called family-Name,
	FamilyName                              varchar(48) NULL,
	-- Person has given-Name,
	GivenName                               varchar(48) NOT NULL,
	UNIQUE(GivenName, FamilyName)
)
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

ALTER TABLE Employment
	ADD FOREIGN KEY (PersonGivenName, PersonFamilyName) REFERENCES Person (GivenName, FamilyName)
GO

