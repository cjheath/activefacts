CREATE TABLE SchoolActivity (
	SchoolName	varchar NOT NULL,
	ActivityName	varchar(32) NOT NULL,
	PRIMARY KEY(SchoolName, ActivityName)
)
GO

CREATE TABLE Student (
	StudentName	varchar NOT NULL,
	SchoolName	varchar NOT NULL,
	PRIMARY KEY(StudentName)
)
GO

CREATE TABLE StudentParticipation (
	StudentName	varchar NOT NULL,
	ActivityName	varchar(32) NOT NULL,
	SchoolName	varchar NOT NULL,
	PRIMARY KEY(StudentName, ActivityName),
	FOREIGN KEY(StudentName)
	REFERENCES Student(StudentName)
)
GO

