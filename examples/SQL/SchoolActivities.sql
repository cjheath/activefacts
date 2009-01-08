CREATE TABLE SchoolActivity (
	-- SchoolActivity is where School sanctions Activity and School has SchoolName,
	SchoolName                              varchar NOT NULL,
	-- SchoolActivity is where School sanctions Activity and Activity has ActivityName,
	ActivityName                            varchar(32) NOT NULL,
	PRIMARY KEY(SchoolName, ActivityName)
)
GO

CREATE TABLE Student (
	-- Student has StudentName,
	StudentName                             varchar NOT NULL,
	-- Student is enrolled in School and School has SchoolName,
	SchoolName                              varchar NOT NULL,
	PRIMARY KEY(StudentName)
)
GO

CREATE TABLE StudentParticipation (
	-- StudentParticipation is where Student represents School in Activity and Student has StudentName,
	StudentName                             varchar NOT NULL,
	-- StudentParticipation is where Student represents School in Activity and School has SchoolName,
	SchoolName                              varchar NOT NULL,
	-- StudentParticipation is where Student represents School in Activity and Activity has ActivityName,
	ActivityName                            varchar(32) NOT NULL,
	PRIMARY KEY(StudentName, ActivityName),
	FOREIGN KEY (StudentName) REFERENCES Student (StudentName)
)
GO

