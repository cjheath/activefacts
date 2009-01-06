CREATE TABLE SchoolActivity (
	SchoolName                              VariableLengthText NOT NULL,
	ActivityName                            VariableLengthText(32) NOT NULL,
	PRIMARY KEY(SchoolName, ActivityName)
)
GO

CREATE TABLE Student (
	StudentName                             VariableLengthText NOT NULL,
	SchoolName                              VariableLengthText NOT NULL,
	PRIMARY KEY(StudentName)
)
GO

CREATE TABLE StudentParticipation (
	StudentName                             VariableLengthText NOT NULL,
	SchoolName                              VariableLengthText NOT NULL,
	ActivityName                            VariableLengthText(32) NOT NULL,
	PRIMARY KEY(StudentName, ActivityName)
)
GO

