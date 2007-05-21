CREATE SCHEMA SchoolActivities
GO

GO

CREATE TABLE SchoolActivities.SchoolSanctionsActivity
(
	School_School_Name NATIONAL CHARACTER VARYING() NOT NULL, 
	Activity_Activity_Name NATIONAL CHARACTER VARYING(32) NOT NULL, 
	CONSTRAINT SchlSnctnsActvtyOncEch PRIMARY KEY(School_School_Name, Activity_Activity_Name)
)
GO


CREATE TABLE SchoolActivities.Student
(
	Student_Name NATIONAL CHARACTER VARYING() NOT NULL, 
	School_School_Name NATIONAL CHARACTER VARYING() NOT NULL, 
	CONSTRAINT StudentNameIsOfOneStudent PRIMARY KEY(Student_Name)
)
GO


CREATE TABLE SchoolActivities.StudentParticipation
(
	School_School_Name NATIONAL CHARACTER VARYING() NOT NULL, 
	Activity_Activity_Name NATIONAL CHARACTER VARYING(32) NOT NULL, 
	Student_Student_Name NATIONAL CHARACTER VARYING() NOT NULL, 
	CONSTRAINT StdntPrtcptnIsFrOnSchl PRIMARY KEY(Student_Student_Name, Activity_Activity_Name)
)
GO


ALTER TABLE SchoolActivities.StudentParticipation ADD CONSTRAINT StudentParticipation_Student_FK FOREIGN KEY (Student_Student_Name)  REFERENCES SchoolActivities.Student (Student_Name)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO



GO