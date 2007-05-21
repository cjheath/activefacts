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



GO