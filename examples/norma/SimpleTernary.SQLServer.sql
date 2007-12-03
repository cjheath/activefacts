CREATE SCHEMA SimpleTernary
GO

GO

CREATE TABLE SimpleTernary.ComputerHasApplicationInstalledByUser
(
	Computer_ComputerId BIGINT NOT NULL,
	User_UserName NATIONAL CHARACTER VARYING() NOT NULL,
	Application NATIONAL CHARACTER VARYING() NOT NULL,
	CONSTRAINT ApplicationIsInstalledOnComputerByEachUserOnce PRIMARY KEY(Application, Computer_ComputerId, User_UserName)
)
GO



GO