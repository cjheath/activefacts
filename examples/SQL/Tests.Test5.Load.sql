CREATE TABLE Party (
	Party_id	int NOT NULL,
	PartyMonikerAccuracy_level	int NULL,
	PartyMonikerPartyName	varchar NOT NULL,
	PersonBirthAttendingDoctor_id	int NULL,
	PersonBirthDateYmd	datetime NULL,
	PersonDeathDeathDateYmd	datetime NULL,
	PersonDied	bit NULL,
	UNIQUE(Party_id)
)
GO

