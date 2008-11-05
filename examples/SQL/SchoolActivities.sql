CREATE TABLE SchoolActivity (
	ActivityName	varchar(32) NOT NULL,
	SchoolName	varchar NOT NULL,
	UNIQUE(SchoolName, ActivityName)
)
GO

CREATE TABLE Student (
	StudentName	varchar NOT NULL,
	SchoolName	varchar NOT NULL,
	UNIQUE(StudentName)
)
GO

CREATE TABLE StudentParticipation (
	ActivityName	varchar(32) NOT NULL,
	StudentName	varchar NOT NULL,
	SchoolName	varchar NOT NULL,
	UNIQUE(StudentName, ActivityName)
)
GO

