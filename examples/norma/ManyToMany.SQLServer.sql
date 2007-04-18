CREATE SCHEMA ManyToMany
GO

GO

CREATE TABLE ManyToMany.Director
(
	Person_Person_Name NATIONAL CHARACTER VARYING() NOT NULL, 
	Company_Company_Name NATIONAL CHARACTER VARYING() NOT NULL, 
	Appointed BIGINT , 
	CONSTRAINT PersonDirectsCompanyOnce PRIMARY KEY(Person_Person_Name, Company_Company_Name)
)
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