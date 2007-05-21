CREATE SCHEMA CompanyDirector
GO

GO

CREATE TABLE CompanyDirector.Attendance
(
	"Date" BIGINT NOT NULL, 
	Director_Person_Person_Name NATIONAL CHARACTER VARYING() NOT NULL, 
	Director_Company_Company_Name NATIONAL CHARACTER VARYING() NOT NULL, 
	CONSTRAINT InternalUniquenessConstraint1 PRIMARY KEY("Date", Director_Person_Person_Name, Director_Company_Company_Name)
)
GO


CREATE TABLE CompanyDirector.Director
(
	Person_Person_Name NATIONAL CHARACTER VARYING() NOT NULL, 
	Company_Company_Name NATIONAL CHARACTER VARYING() NOT NULL, 
	Appointed BIGINT , 
	CONSTRAINT PersonDirectsCompanyOnce PRIMARY KEY(Person_Person_Name, Company_Company_Name)
)
GO


ALTER TABLE CompanyDirector.Attendance ADD CONSTRAINT Attendance_Director_FK FOREIGN KEY (Director_Person_Person_Name, Director_Company_Company_Name)  REFERENCES CompanyDirector.Director (Person_Person_Name, Company_Company_Name)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO



GO