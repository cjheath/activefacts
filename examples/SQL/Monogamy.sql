CREATE TABLE Person (
	-- Person has PersonID,
	PersonID                                int IDENTITY NOT NULL,
	-- Person is called Name,
	Name                                    varchar NOT NULL,
	-- maybe Girl is a subtype of Person and maybe Girlfriend is going out with Boyfriend and Person has PersonID,
	GirlBoyfriendID                         int NULL,
	PRIMARY KEY(PersonID),
	FOREIGN KEY (GirlBoyfriendID) REFERENCES Person (PersonID)
)
GO

