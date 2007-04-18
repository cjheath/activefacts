CREATE SCHEMA SimpleTernary
GO

GO

CREATE TABLE SimpleTernary.CmptrHsApplctnInstlldByUsr
(
	Computer_Computer_Id BIGINT NOT NULL, 
	User_User_Name NATIONAL CHARACTER VARYING() NOT NULL, 
	Application NATIONAL CHARACTER VARYING() NOT NULL, 
	CONSTRAINT AIIOCBEUO PRIMARY KEY(Application, Computer_Computer_Id, User_User_Name)
)
GO



CREATE PROCEDURE SimpleTernary.ICHAIBU
(
	@Computer_Computer_Id BIGINT , 
	@User_User_Name NATIONAL CHARACTER VARYING() , 
	@Application NATIONAL CHARACTER VARYING() 
)
AS
	INSERT INTO SimpleTernary.CmptrHsApplctnInstlldByUsr(Computer_Computer_Id, User_User_Name, Application)
	VALUES (@Computer_Computer_Id, @User_User_Name, @Application)
GO


CREATE PROCEDURE SimpleTernary.DltCmptrHsApplctnInstlldByUsr
(
	@Application NATIONAL CHARACTER VARYING() , 
	@Computer_Computer_Id BIGINT , 
	@User_User_Name NATIONAL CHARACTER VARYING() 
)
AS
	DELETE FROM SimpleTernary.CmptrHsApplctnInstlldByUsr
	WHERE Application = @Application AND 
Computer_Computer_Id = @Computer_Computer_Id AND 
User_User_Name = @User_User_Name
GO


CREATE PROCEDURE SimpleTernary.UCHAIBUCCI
(
	@old_Application NATIONAL CHARACTER VARYING() , 
	@old_Computer_Computer_Id BIGINT , 
	@old_User_User_Name NATIONAL CHARACTER VARYING() , 
	@Computer_Computer_Id BIGINT 
)
AS
	UPDATE SimpleTernary.CmptrHsApplctnInstlldByUsr
SET Computer_Computer_Id = @Computer_Computer_Id
	WHERE Application = @old_Application AND 
Computer_Computer_Id = @old_Computer_Computer_Id AND 
User_User_Name = @old_User_User_Name
GO


CREATE PROCEDURE SimpleTernary.UCHAIBUUUN
(
	@old_Application NATIONAL CHARACTER VARYING() , 
	@old_Computer_Computer_Id BIGINT , 
	@old_User_User_Name NATIONAL CHARACTER VARYING() , 
	@User_User_Name NATIONAL CHARACTER VARYING() 
)
AS
	UPDATE SimpleTernary.CmptrHsApplctnInstlldByUsr
SET User_User_Name = @User_User_Name
	WHERE Application = @old_Application AND 
Computer_Computer_Id = @old_Computer_Computer_Id AND 
User_User_Name = @old_User_User_Name
GO


CREATE PROCEDURE SimpleTernary.UCHAIBUA
(
	@old_Application NATIONAL CHARACTER VARYING() , 
	@old_Computer_Computer_Id BIGINT , 
	@old_User_User_Name NATIONAL CHARACTER VARYING() , 
	@Application NATIONAL CHARACTER VARYING() 
)
AS
	UPDATE SimpleTernary.CmptrHsApplctnInstlldByUsr
SET Application = @Application
	WHERE Application = @old_Application AND 
Computer_Computer_Id = @old_Computer_Computer_Id AND 
User_User_Name = @old_User_User_Name
GO


GO