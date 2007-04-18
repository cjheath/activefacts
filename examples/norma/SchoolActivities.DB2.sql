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


CREATE PROCEDURE SchoolActivities.InsertSchoolSanctionsActivity
(
	School_School_Name CHARACTER VARYING() , 
	Activity_Activity_Name CHARACTER VARYING(32) 
)
AS
	INSERT INTO SchoolActivities.SchoolSanctionsActivity(School_School_Name, Activity_Activity_Name)
	VALUES (School_School_Name, Activity_Activity_Name);

CREATE PROCEDURE SchoolActivities.DeleteSchoolSanctionsActivity
(
	School_School_Name CHARACTER VARYING() , 
	Activity_Activity_Name CHARACTER VARYING(32) 
)
AS
	DELETE FROM SchoolActivities.SchoolSanctionsActivity
	WHERE School_School_Name = School_School_Name AND 
Activity_Activity_Name = Activity_Activity_Name;

CREATE PROCEDURE SchoolActivities.USSASSN
(
	old_School_School_Name CHARACTER VARYING() , 
	old_Activity_Activity_Name CHARACTER VARYING(32) , 
	School_School_Name CHARACTER VARYING() 
)
AS
	UPDATE SchoolActivities.SchoolSanctionsActivity
SET School_School_Name = School_School_Name
	WHERE School_School_Name = old_School_School_Name AND 
Activity_Activity_Name = old_Activity_Activity_Name;

CREATE PROCEDURE SchoolActivities.USSAAAN
(
	old_School_School_Name CHARACTER VARYING() , 
	old_Activity_Activity_Name CHARACTER VARYING(32) , 
	Activity_Activity_Name CHARACTER VARYING(32) 
)
AS
	UPDATE SchoolActivities.SchoolSanctionsActivity
SET Activity_Activity_Name = Activity_Activity_Name
	WHERE School_School_Name = old_School_School_Name AND 
Activity_Activity_Name = old_Activity_Activity_Name;

CREATE PROCEDURE SchoolActivities.InsertStudent
(
	Student_Name CHARACTER VARYING() , 
	School_School_Name CHARACTER VARYING() 
)
AS
	INSERT INTO SchoolActivities.Student(Student_Name, School_School_Name)
	VALUES (Student_Name, School_School_Name);

CREATE PROCEDURE SchoolActivities.DeleteStudent
(
	Student_Name CHARACTER VARYING() 
)
AS
	DELETE FROM SchoolActivities.Student
	WHERE Student_Name = Student_Name;

CREATE PROCEDURE SchoolActivities.UpdateStudentStudent_Name
(
	old_Student_Name CHARACTER VARYING() , 
	Student_Name CHARACTER VARYING() 
)
AS
	UPDATE SchoolActivities.Student
SET Student_Name = Student_Name
	WHERE Student_Name = old_Student_Name;

CREATE PROCEDURE SchoolActivities.UpdtStdntSchl_Schl_Nm
(
	old_Student_Name CHARACTER VARYING() , 
	School_School_Name CHARACTER VARYING() 
)
AS
	UPDATE SchoolActivities.Student
SET School_School_Name = School_School_Name
	WHERE Student_Name = old_Student_Name;

CREATE PROCEDURE SchoolActivities.InsertStudentParticipation
(
	School_School_Name CHARACTER VARYING() , 
	Activity_Activity_Name CHARACTER VARYING(32) , 
	Student_Student_Name CHARACTER VARYING() 
)
AS
	INSERT INTO SchoolActivities.StudentParticipation(School_School_Name, Activity_Activity_Name, Student_Student_Name)
	VALUES (School_School_Name, Activity_Activity_Name, Student_Student_Name);

CREATE PROCEDURE SchoolActivities.DeleteStudentParticipation
(
	Student_Student_Name CHARACTER VARYING() , 
	Activity_Activity_Name CHARACTER VARYING(32) 
)
AS
	DELETE FROM SchoolActivities.StudentParticipation
	WHERE Student_Student_Name = Student_Student_Name AND 
Activity_Activity_Name = Activity_Activity_Name;

CREATE PROCEDURE SchoolActivities.UpdtStdntPrtcptnSchl_Schl_Nm
(
	old_Student_Student_Name CHARACTER VARYING() , 
	old_Activity_Activity_Name CHARACTER VARYING(32) , 
	School_School_Name CHARACTER VARYING() 
)
AS
	UPDATE SchoolActivities.StudentParticipation
SET School_School_Name = School_School_Name
	WHERE Student_Student_Name = old_Student_Student_Name AND 
Activity_Activity_Name = old_Activity_Activity_Name;

CREATE PROCEDURE SchoolActivities.USPAAN
(
	old_Student_Student_Name CHARACTER VARYING() , 
	old_Activity_Activity_Name CHARACTER VARYING(32) , 
	Activity_Activity_Name CHARACTER VARYING(32) 
)
AS
	UPDATE SchoolActivities.StudentParticipation
SET Activity_Activity_Name = Activity_Activity_Name
	WHERE Student_Student_Name = old_Student_Student_Name AND 
Activity_Activity_Name = old_Activity_Activity_Name;

CREATE PROCEDURE SchoolActivities.UpdtStdntPrtcptnStdnt_Stdnt_Nm
(
	old_Student_Student_Name CHARACTER VARYING() , 
	old_Activity_Activity_Name CHARACTER VARYING(32) , 
	Student_Student_Name CHARACTER VARYING() 
)
AS
	UPDATE SchoolActivities.StudentParticipation
SET Student_Student_Name = Student_Student_Name
	WHERE Student_Student_Name = old_Student_Student_Name AND 
Activity_Activity_Name = old_Activity_Activity_Name;
COMMIT;

