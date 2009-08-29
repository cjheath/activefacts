CREATE TABLE Person (
	-- maybe Girl is a kind of Person and maybe Girlfriend is going out with Boyfriend and Person has PersonID,
	GirlBoyfriendID                         int NULL,
	-- Person is called Name,
	Name                                    varchar NOT NULL,
	-- Person has PersonID,
	PersonID                                int IDENTITY NOT NULL,
	PRIMARY KEY(PersonID),
	FOREIGN KEY (GirlBoyfriendID) REFERENCES Person (PersonID)
)
GO

CREATE VIEW dbo.GirlInPerson_BoyfriendID (GirlBoyfriendID) WITH SCHEMABINDING AS
	SELECT GirlBoyfriendID FROM dbo.Person
	WHERE	GirlBoyfriendID IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_GirlInPersonByGirlBoyfriendID ON dbo.GirlInPerson_BoyfriendID(GirlBoyfriendID)
GO

