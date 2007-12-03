CREATE SCHEMA SchoolActivities;

SET SCHEMA 'SCHOOLACTIVITIES';

CREATE TABLE SchoolActivities.SchoolSanctionsActivity
(
	School_SchoolName CHARACTER VARYING() NOT NULL,
	Activity_ActivityName CHARACTER VARYING(32) NOT NULL,
	CONSTRAINT SchoolSanctionsActivityOnceEach PRIMARY KEY(School_SchoolName, Activity_ActivityName)
);

CREATE TABLE SchoolActivities.Student
(
	StudentName CHARACTER VARYING() NOT NULL,
	School_SchoolName CHARACTER VARYING() NOT NULL,
	CONSTRAINT StudentNameIsOfOneStudent PRIMARY KEY(StudentName)
);

CREATE TABLE SchoolActivities.StudentParticipation
(
	School_SchoolName CHARACTER VARYING() NOT NULL,
	Activity_ActivityName CHARACTER VARYING(32) NOT NULL,
	Student_StudentName CHARACTER VARYING() NOT NULL,
	CONSTRAINT StudentParticipationIsForOneSchool PRIMARY KEY(Student_StudentName, Activity_ActivityName)
);

ALTER TABLE SchoolActivities.StudentParticipation ADD CONSTRAINT Student_FK FOREIGN KEY (Student_StudentName) REFERENCES SchoolActivities.Student (StudentName) ON DELETE RESTRICT ON UPDATE RESTRICT;

COMMIT;

