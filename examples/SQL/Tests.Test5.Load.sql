CREATE TABLE Party (
	-- Party has Party Id,
	PartyId                                 int IDENTITY NOT NULL,
	-- Party Moniker is where Party is called Party Name and Party Moniker has Accuracy and Accuracy has Accuracy Level,
	PartyMonikerAccuracyLevel               int NOT NULL CHECK((PartyMonikerAccuracyLevel >= 1 AND PartyMonikerAccuracyLevel <= 5)),
	-- Party Moniker is where Party is called Party Name and Party Moniker is where Party is called Party Name,
	PartyMonikerPartyName                   varchar NOT NULL,
	-- maybe Person is a kind of Party and Birth is where Person was born on Event Date and maybe Birth was assisted by attending-Doctor and Party has Party Id,
	PersonAttendingDoctorId                 int NULL,
	-- maybe Person is a kind of Party and Death is where Person died and maybe Death occurred on death-Event Date and Event Date has ymd,
	PersonDeathEventDateYmd                 datetime NULL,
	-- maybe Person is a kind of Party and Birth is where Person was born on Event Date and Birth is where Person was born on Event Date and Event Date has ymd,
	PersonEventDateYmd                      datetime NULL,
	PRIMARY KEY(PartyId),
	FOREIGN KEY (PersonAttendingDoctorId) REFERENCES Party (PartyId)
)
GO

CREATE VIEW dbo.BirthInParty_PersonAttendingDoctorIdPersonEventDateYmd (PersonAttendingDoctorId, PersonEventDateYmd) WITH SCHEMABINDING AS
	SELECT PersonAttendingDoctorId, PersonEventDateYmd FROM dbo.Party
	WHERE	PersonAttendingDoctorId IS NOT NULL
	  AND	PersonEventDateYmd IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX PersonMustHaveSupertypeParty ON dbo.BirthInParty_PersonAttendingDoctorIdPersonEventDateYmd(PersonAttendingDoctorId, PersonEventDateYmd)
GO

