CREATE SCHEMA ManyToMany
GO

GO

CREATE TABLE ManyToMany.DrctrAttnddBrdMtngOnDt
(
	"Date" BIGINT NOT NULL, 
	Director_Person_Person_Name NATIONAL CHARACTER VARYING() NOT NULL, 
	Director_Company_Company_Name NATIONAL CHARACTER VARYING() NOT NULL, 
	CONSTRAINT InternalUniquenessConstraint1 PRIMARY KEY("Date", Director_Person_Person_Name, Director_Company_Company_Name)
)
GO


CREATE TABLE ManyToMany.Director
(
	Person_Person_Name NATIONAL CHARACTER VARYING() NOT NULL, 
	Company_Company_Name NATIONAL CHARACTER VARYING() NOT NULL, 
	Appointed BIGINT , 
	CONSTRAINT PersonDirectsCompanyOnce PRIMARY KEY(Person_Person_Name, Company_Company_Name)
)
GO


ALTER TABLE ManyToMany.DrctrAttnddBrdMtngOnDt ADD CONSTRAINT DrctrAttnddBrdMtngOnDt_Director_FK FOREIGN KEY (Director_Person_Person_Name, Director_Company_Company_Name)  REFERENCES ManyToMany.Director (Person_Person_Name, Company_Company_Name)  ON DELETE NO ACTION ON UPDATE NO ACTION
GO



CREATE PROCEDURE ManyToMany.InsrtDrctrAttnddBrdMtngOnDt
(
	@"Date" BIGINT , 
	@Director_Person_Person_Name NATIONAL CHARACTER VARYING() , 
	@Director_Company_Company_Name NATIONAL CHARACTER VARYING() 
)
AS
	INSERT INTO ManyToMany.DrctrAttnddBrdMtngOnDt("Date", Director_Person_Person_Name, Director_Company_Company_Name)
	VALUES (@"Date", @Director_Person_Person_Name, @Director_Company_Company_Name)
GO


CREATE PROCEDURE ManyToMany.DltDrctrAttnddBrdMtngOnDt
(
	@"Date" BIGINT , 
	@Director_Person_Person_Name NATIONAL CHARACTER VARYING() , 
	@Director_Company_Company_Name NATIONAL CHARACTER VARYING() 
)
AS
	DELETE FROM ManyToMany.DrctrAttnddBrdMtngOnDt
	WHERE "Date" = @"Date" AND 
Director_Person_Person_Name = @Director_Person_Person_Name AND 
Director_Company_Company_Name = @Director_Company_Company_Name
GO


CREATE PROCEDURE ManyToMany."UpdtDrctrAttnddBrdMtngOnDt""Dt"""
(
	@"old_""Date""" BIGINT , 
	@Old_Drctr_Prsn_Prsn_Nm NATIONAL CHARACTER VARYING() , 
	@Old_Drctr_Cmpny_Cmpny_Nm NATIONAL CHARACTER VARYING() , 
	@"Date" BIGINT 
)
AS
	UPDATE ManyToMany.DrctrAttnddBrdMtngOnDt
SET "Date" = @"Date"
	WHERE "Date" = @"old_""Date""" AND 
Director_Person_Person_Name = @Old_Drctr_Prsn_Prsn_Nm AND 
Director_Company_Company_Name = @Old_Drctr_Cmpny_Cmpny_Nm
GO


CREATE PROCEDURE ManyToMany.UDABMODDPPN
(
	@"old_""Date""" BIGINT , 
	@Old_Drctr_Prsn_Prsn_Nm NATIONAL CHARACTER VARYING() , 
	@Old_Drctr_Cmpny_Cmpny_Nm NATIONAL CHARACTER VARYING() , 
	@Director_Person_Person_Name NATIONAL CHARACTER VARYING() 
)
AS
	UPDATE ManyToMany.DrctrAttnddBrdMtngOnDt
SET Director_Person_Person_Name = @Director_Person_Person_Name
	WHERE "Date" = @"old_""Date""" AND 
Director_Person_Person_Name = @Old_Drctr_Prsn_Prsn_Nm AND 
Director_Company_Company_Name = @Old_Drctr_Cmpny_Cmpny_Nm
GO


CREATE PROCEDURE ManyToMany.UDABMODDCCN
(
	@"old_""Date""" BIGINT , 
	@Old_Drctr_Prsn_Prsn_Nm NATIONAL CHARACTER VARYING() , 
	@Old_Drctr_Cmpny_Cmpny_Nm NATIONAL CHARACTER VARYING() , 
	@Director_Company_Company_Name NATIONAL CHARACTER VARYING() 
)
AS
	UPDATE ManyToMany.DrctrAttnddBrdMtngOnDt
SET Director_Company_Company_Name = @Director_Company_Company_Name
	WHERE "Date" = @"old_""Date""" AND 
Director_Person_Person_Name = @Old_Drctr_Prsn_Prsn_Nm AND 
Director_Company_Company_Name = @Old_Drctr_Cmpny_Cmpny_Nm
GO


CREATE PROCEDURE ManyToMany.InsertDirector
(
	@Person_Person_Name NATIONAL CHARACTER VARYING() , 
	@Company_Company_Name NATIONAL CHARACTER VARYING() , 
	@Appointed BIGINT 
)
AS
	INSERT INTO ManyToMany.Director(Person_Person_Name, Company_Company_Name, Appointed)
	VALUES (@Person_Person_Name, @Company_Company_Name, @Appointed)
GO


CREATE PROCEDURE ManyToMany.DeleteDirector
(
	@Person_Person_Name NATIONAL CHARACTER VARYING() , 
	@Company_Company_Name NATIONAL CHARACTER VARYING() 
)
AS
	DELETE FROM ManyToMany.Director
	WHERE Person_Person_Name = @Person_Person_Name AND 
Company_Company_Name = @Company_Company_Name
GO


CREATE PROCEDURE ManyToMany.UpdtDrctrPrsn_Prsn_Nm
(
	@old_Person_Person_Name NATIONAL CHARACTER VARYING() , 
	@old_Company_Company_Name NATIONAL CHARACTER VARYING() , 
	@Person_Person_Name NATIONAL CHARACTER VARYING() 
)
AS
	UPDATE ManyToMany.Director
SET Person_Person_Name = @Person_Person_Name
	WHERE Person_Person_Name = @old_Person_Person_Name AND 
Company_Company_Name = @old_Company_Company_Name
GO


CREATE PROCEDURE ManyToMany.UpdtDrctrCmpny_Cmpny_Nm
(
	@old_Person_Person_Name NATIONAL CHARACTER VARYING() , 
	@old_Company_Company_Name NATIONAL CHARACTER VARYING() , 
	@Company_Company_Name NATIONAL CHARACTER VARYING() 
)
AS
	UPDATE ManyToMany.Director
SET Company_Company_Name = @Company_Company_Name
	WHERE Person_Person_Name = @old_Person_Person_Name AND 
Company_Company_Name = @old_Company_Company_Name
GO


CREATE PROCEDURE ManyToMany.UpdateDirectorAppointed
(
	@old_Person_Person_Name NATIONAL CHARACTER VARYING() , 
	@old_Company_Company_Name NATIONAL CHARACTER VARYING() , 
	@Appointed BIGINT 
)
AS
	UPDATE ManyToMany.Director
SET Appointed = @Appointed
	WHERE Person_Person_Name = @old_Person_Person_Name AND 
Company_Company_Name = @old_Company_Company_Name
GO


GO