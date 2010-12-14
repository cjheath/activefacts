CREATE TABLE Marriage (
	-- Marriage is by husband-Person and Person has family-Name,
	HusbandFamilyName                       varchar NOT NULL,
	-- Marriage is by husband-Person and Person has given-Name,
	HusbandGivenName                        varchar NOT NULL,
	-- Marriage is of wife-Person and Person has family-Name,
	WifeFamilyName                          varchar NOT NULL,
	-- Marriage is of wife-Person and Person has given-Name,
	WifeGivenName                           varchar NOT NULL,
	PRIMARY KEY(HusbandGivenName, HusbandFamilyName, WifeGivenName, WifeFamilyName)
)
GO

CREATE TABLE Person (
	-- Person has family-Name,
	FamilyName                              varchar NOT NULL,
	-- Person has given-Name,
	GivenName                               varchar NOT NULL,
	PRIMARY KEY(GivenName, FamilyName)
)
GO

ALTER TABLE Marriage
	ADD FOREIGN KEY (HusbandFamilyName, HusbandGivenName) REFERENCES Person (FamilyName, GivenName)
GO

ALTER TABLE Marriage
	ADD FOREIGN KEY (WifeFamilyName, WifeGivenName) REFERENCES Person (FamilyName, GivenName)
GO

