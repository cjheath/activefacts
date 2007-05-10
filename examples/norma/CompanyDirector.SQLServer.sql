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



CREATE PROCEDURE CompanyDirector.InsertAttendance
(
	@"Date" BIGINT , 
	@Director_Person_Person_Name NATIONAL CHARACTER VARYING() , 
	@Director_Company_Company_Name NATIONAL CHARACTER VARYING() 
)
AS
	INSERT INTO CompanyDirector.Attendance("Date", Director_Person_Person_Name, Director_Company_Company_Name)
	VALUES (@"Date", @Director_Person_Person_Name, @Director_Company_Company_Name)
GO


CREATE PROCEDURE CompanyDirector.DeleteAttendance
(
	@"Date" BIGINT , 
	@Director_Person_Person_Name NATIONAL CHARACTER VARYING() , 
	@Director_Company_Company_Name NATIONAL CHARACTER VARYING() 
)
AS
	DELETE FROM CompanyDirector.Attendance
	WHERE "Date" = @"Date" AND 
Director_Person_Person_Name = @Director_Person_Person_Name AND 
Director_Company_Company_Name = @Director_Company_Company_Name
GO


CREATE PROCEDURE CompanyDirector."UpdateAttendance""Date"""
(
	@"old_""Date""" BIGINT , 
	@Old_Drctr_Prsn_Prsn_Nm NATIONAL CHARACTER VARYING() , 
	@Old_Drctr_Cmpny_Cmpny_Nm NATIONAL CHARACTER VARYING() , 
	@"Date" BIGINT 
)
AS
	UPDATE CompanyDirector.Attendance
SET "Date" = @"Date"
	WHERE "Date" = @"old_""Date""" AND 
Director_Person_Person_Name = @Old_Drctr_Prsn_Prsn_Nm AND 
Director_Company_Company_Name = @Old_Drctr_Cmpny_Cmpny_Nm
GO


CREATE PROCEDURE CompanyDirector.UpdtAttndncDrctr_Prsn_Prsn_Nm
(
	@"old_""Date""" BIGINT , 
	@Old_Drctr_Prsn_Prsn_Nm NATIONAL CHARACTER VARYING() , 
	@Old_Drctr_Cmpny_Cmpny_Nm NATIONAL CHARACTER VARYING() , 
	@Director_Person_Person_Name NATIONAL CHARACTER VARYING() 
)
AS
	UPDATE CompanyDirector.Attendance
SET Director_Person_Person_Name = @Director_Person_Person_Name
	WHERE "Date" = @"old_""Date""" AND 
Director_Person_Person_Name = @Old_Drctr_Prsn_Prsn_Nm AND 
Director_Company_Company_Name = @Old_Drctr_Cmpny_Cmpny_Nm
GO


CREATE PROCEDURE CompanyDirector.UADCCN
(
	@"old_""Date""" BIGINT , 
	@Old_Drctr_Prsn_Prsn_Nm NATIONAL CHARACTER VARYING() , 
	@Old_Drctr_Cmpny_Cmpny_Nm NATIONAL CHARACTER VARYING() , 
	@Director_Company_Company_Name NATIONAL CHARACTER VARYING() 
)
AS
	UPDATE CompanyDirector.Attendance
SET Director_Company_Company_Name = @Director_Company_Company_Name
	WHERE "Date" = @"old_""Date""" AND 
Director_Person_Person_Name = @Old_Drctr_Prsn_Prsn_Nm AND 
Director_Company_Company_Name = @Old_Drctr_Cmpny_Cmpny_Nm
GO


CREATE PROCEDURE CompanyDirector.InsertDirector
(
	@Person_Person_Name NATIONAL CHARACTER VARYING() , 
	@Company_Company_Name NATIONAL CHARACTER VARYING() , 
	@Appointed BIGINT 
)
AS
	INSERT INTO CompanyDirector.Director(Person_Person_Name, Company_Company_Name, Appointed)
	VALUES (@Person_Person_Name, @Company_Company_Name, @Appointed)
GO


CREATE PROCEDURE CompanyDirector.DeleteDirector
(
	@Person_Person_Name NATIONAL CHARACTER VARYING() , 
	@Company_Company_Name NATIONAL CHARACTER VARYING() 
)
AS
	DELETE FROM CompanyDirector.Director
	WHERE Person_Person_Name = @Person_Person_Name AND 
Company_Company_Name = @Company_Company_Name
GO


CREATE PROCEDURE CompanyDirector.UpdtDrctrPrsn_Prsn_Nm
(
	@old_Person_Person_Name NATIONAL CHARACTER VARYING() , 
	@old_Company_Company_Name NATIONAL CHARACTER VARYING() , 
	@Person_Person_Name NATIONAL CHARACTER VARYING() 
)
AS
	UPDATE CompanyDirector.Director
SET Person_Person_Name = @Person_Person_Name
	WHERE Person_Person_Name = @old_Person_Person_Name AND 
Company_Company_Name = @old_Company_Company_Name
GO


CREATE PROCEDURE CompanyDirector.UpdtDrctrCmpny_Cmpny_Nm
(
	@old_Person_Person_Name NATIONAL CHARACTER VARYING() , 
	@old_Company_Company_Name NATIONAL CHARACTER VARYING() , 
	@Company_Company_Name NATIONAL CHARACTER VARYING() 
)
AS
	UPDATE CompanyDirector.Director
SET Company_Company_Name = @Company_Company_Name
	WHERE Person_Person_Name = @old_Person_Person_Name AND 
Company_Company_Name = @old_Company_Company_Name
GO


CREATE PROCEDURE CompanyDirector.UpdateDirectorAppointed
(
	@old_Person_Person_Name NATIONAL CHARACTER VARYING() , 
	@old_Company_Company_Name NATIONAL CHARACTER VARYING() , 
	@Appointed BIGINT 
)
AS
	UPDATE CompanyDirector.Director
SET Appointed = @Appointed
	WHERE Person_Person_Name = @old_Person_Person_Name AND 
Company_Company_Name = @old_Company_Company_Name
GO


GO