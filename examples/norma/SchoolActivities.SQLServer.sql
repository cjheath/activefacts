CREATE SCHEMA SchoolActivities
GO

GO

CREATE TABLE SchoolActivities.SchoolSanctionsActivity
(
	School_SchoolName NATIONAL CHARACTER VARYING() NOT NULL,
	Activity_ActivityName NATIONAL CHARACTER VARYING(32) NOT NULL,
	CONSTRAINT SchoolSanctionsActivityOnceEach PRIMARY KEY(School_SchoolName, Activity_ActivityName)
)
GO


CREATE TABLE SchoolActivities.Student
(
	StudentName NATIONAL CHARACTER VARYING() NOT NULL,
	School_SchoolName NATIONAL CHARACTER VARYING() NOT NULL,
	CONSTRAINT StudentNameIsOfOneStudent PRIMARY KEY(StudentName)
)
GO


CREATE TABLE SchoolActivities.StudentParticipation
(
	School_SchoolName NATIONAL CHARACTER VARYING() NOT NULL,
	Activity_ActivityName NATIONAL CHARACTER VARYING(32) NOT NULL,
	Student_StudentName NATIONAL CHARACTER VARYING() NOT NULL,
	CONSTRAINT StudentParticipationIsForOneSchool PRIMARY KEY(Student_StudentName, Activity_ActivityName)
)
GO


ALTER TABLE SchoolActivities.StudentParticipation ADD CONSTRAINT StudentParticipation_Student_FK FOREIGN KEY (Student_StudentName) REFERENCES SchoolActivities.Student (StudentName) ON DELETE NO ACTION ON UPDATE NO ACTION
GO



GO