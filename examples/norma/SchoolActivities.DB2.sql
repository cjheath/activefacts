CREATE SCHEMA SchoolActivities;

SET SCHEMA 'SCHOOLACTIVITIES';

CREATE TABLE SchoolActivities.SchoolSanctionsActivity
(
	School_School_Name CHARACTER VARYING() NOT NULL, 
	Activity_Activity_Name CHARACTER VARYING(32) NOT NULL, 
	CONSTRAINT SchlSnctnsActvtyOncEch PRIMARY KEY(School_School_Name, Activity_Activity_Name)
);

CREATE TABLE SchoolActivities.Student
(
	Student_Name CHARACTER VARYING() NOT NULL, 
	School_School_Name CHARACTER VARYING() NOT NULL, 
	CONSTRAINT StudentNameIsOfOneStudent PRIMARY KEY(Student_Name)
);

CREATE TABLE SchoolActivities.StudentParticipation
(
	School_School_Name CHARACTER VARYING() NOT NULL, 
	Activity_Activity_Name CHARACTER VARYING(32) NOT NULL, 
	Student_Student_Name CHARACTER VARYING() NOT NULL, 
	CONSTRAINT StdntPrtcptnIsFrOnSchl PRIMARY KEY(Student_Student_Name, Activity_Activity_Name)
);

ALTER TABLE SchoolActivities.StudentParticipation ADD CONSTRAINT Student_FK FOREIGN KEY (Student_Student_Name)  REFERENCES SchoolActivities.Student (Student_Name)  ON DELETE RESTRICT ON UPDATE RESTRICT;

COMMIT;

