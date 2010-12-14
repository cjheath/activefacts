CREATE TABLE Person (
	-- maybe Girl is a kind of Person and maybe Girl is going out with Boy and Person has Person ID,
	GirlBoyfriendID                         int NULL,
	-- Person is called Name,
	Name                                    varchar NOT NULL,
	-- Person has Person ID,
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

