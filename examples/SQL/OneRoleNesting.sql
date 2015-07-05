CREATE TABLE Party (
	-- Party has Party Id,
	PartyId                                 int IDENTITY NOT NULL,
	-- Party is involved in Party Moniker and Party Moniker has Accuracy and Accuracy has Accuracy Level,
	PartyMonikerAccuracyLevel               int NOT NULL CHECK((PartyMonikerAccuracyLevel >= 1 AND PartyMonikerAccuracyLevel <= 5)),
	-- Party is involved in Party Moniker and Party Moniker involves Party Name,
	PartyMonikerPartyName                   varchar NOT NULL,
	-- maybe Party is a Person and Person is involved in Birth and maybe Birth was assisted by attending-Doctor and Doctor is a kind of Person and Person is a kind of Party and Party has Party Id,
	PersonAttendingDoctorId                 int NULL,
	-- maybe Party is a Person and Person is involved in Death and maybe Death occurred on death-Event Date and Event Date has ymd,
	PersonDeathEventDateYmd                 datetime NULL,
	-- maybe Party is a Person and Person is involved in Death,
	PersonDied                              bit NULL,
	-- maybe Party is a Person and Person is involved in Birth and Birth involves Event Date and Event Date has ymd,
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

