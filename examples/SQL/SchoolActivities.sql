CREATE TABLE SchoolActivity (
	-- School Activity involves Activity and Activity has Activity Name,
	ActivityName                            varchar(32) NOT NULL,
	-- School Activity involves School and School has School Name,
	SchoolName                              varchar NOT NULL,
	PRIMARY KEY(SchoolName, ActivityName)
)
GO

CREATE TABLE Student (
	-- Student is enrolled in School and School has School Name,
	SchoolName                              varchar NOT NULL,
	-- Student has Student Name,
	StudentName                             varchar NOT NULL,
	PRIMARY KEY(StudentName)
)
GO

CREATE TABLE StudentParticipation (
	-- Student Participation involves Activity and Activity has Activity Name,
	ActivityName                            varchar(32) NOT NULL,
	-- Student Participation involves School and School has School Name,
	SchoolName                              varchar NOT NULL,
	-- Student Participation involves Student and Student has Student Name,
	StudentName                             varchar NOT NULL,
	PRIMARY KEY(StudentName, ActivityName),
	FOREIGN KEY (StudentName) REFERENCES Student (StudentName)
)
GO

