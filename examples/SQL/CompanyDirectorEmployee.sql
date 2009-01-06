CREATE TABLE Attendance (
	AttendeeGivenName                       VariableLengthText(48) NOT NULL,
	AttendeeFamilyName                      VariableLengthText(48) NULL,
	MeetingDate                             Date NOT NULL,
	MeetingIsBoardMeeting                   BIT NOT NULL,
	MeetingCompanyName                      VariableLengthText(48) NOT NULL,
	UNIQUE(AttendeeGivenName, AttendeeFamilyName, MeetingDate, MeetingIsBoardMeeting, MeetingCompanyName)
)
GO

CREATE TABLE Company (
	CompanyName                             VariableLengthText(48) NOT NULL,
	IsListed                                BIT NOT NULL,
	PRIMARY KEY(CompanyName)
)
GO

CREATE TABLE Directorship (
	DirectorGivenName                       VariableLengthText(48) NOT NULL,
	DirectorFamilyName                      VariableLengthText(48) NULL,
	CompanyName                             VariableLengthText(48) NOT NULL,
	AppointmentDate                         Date NOT NULL,
	UNIQUE(DirectorGivenName, DirectorFamilyName, CompanyName)
)
GO

CREATE TABLE Person (
	GivenName                               VariableLengthText(48) NOT NULL,
	BirthDate                               Date NULL CHECK(REVISIT: valid value),
	FamilyName                              VariableLengthText(48) NULL,
	EmployeeNr                              SignedInteger(32) NULL,
	EmployeeCompanyName                     VariableLengthText(48) NULL,
	EmployeeManagerNr                       SignedInteger(32) NULL,
	ManagerIsCeo                            BIT NULL,
	UNIQUE(GivenName, FamilyName)
)
GO

