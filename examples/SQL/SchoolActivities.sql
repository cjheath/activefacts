CREATE TABLE Student (
	SchoolName	varchar NOT NULL,
	StudentName	varchar NOT NULL,
	UNIQUE(StudentName)
)
GO

CREATE TABLE StudentParticipation (
	SchoolName	varchar NOT NULL,
	ActivityName	varchar(32) NOT NULL,
	StudentName	varchar NOT NULL,
	UNIQUE(StudentName, ActivityName)
)
GO

CREATE TABLE SchoolActivity (
	SchoolName	varchar NOT NULL,
	ActivityName	varchar(32) NOT NULL,
	UNIQUE(SchoolName, ActivityName)
)
GO

