CREATE TABLE Party (
	-- Party has Party Id,
	PartyId                                 int IDENTITY NOT NULL,
	-- Party Moniker (in which Party is called Party Name) and Party Moniker has Accuracy and Accuracy has Accuracy Level,
	PartyMonikerAccuracyLevel               int NOT NULL CHECK((PartyMonikerAccuracyLevel >= 1 AND PartyMonikerAccuracyLevel <= 5)),
	-- Party Moniker (in which Party is called Party Name) and Party Moniker (in which Party is called Party Name) involves Party Name,
	PartyMonikerPartyName                   varchar NOT NULL,
	-- maybe Party is a Person and Birth (in which Person was born on Event Date) and maybe Birth was assisted by attending-Doctor and Doctor is a kind of Person and Person is a kind of Party and Party has Party Id,
	PersonAttendingDoctorId                 int NULL,
	-- maybe Party is a Person and Death (in which Person died) and maybe Death occurred on death-Event Date and Event Date has ymd,
	PersonDeathEventDateYmd                 datetime NULL,
	-- maybe Party is a Person and Person died,
	PersonDied                              bit NULL,
	-- maybe Party is a Person and Birth (in which Person was born on Event Date) and Birth (in which Person was born on Event Date) and Event Date has ymd,
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

