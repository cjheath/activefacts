CREATE TABLE Party (
	PersonBirthDateYmd	datetime NULL,
	PersonBirthAttendingDoctor_id	int NULL,
	PersonDied	bit NULL,
	PersonDeathDeathDateYmd	datetime NULL,
	Party_id	int NOT NULL,
	PartyMonikerAccuracy_level	int NULL,
	PartyMonikerPartyName	varchar NOT NULL,
	UNIQUE(Party_id)
)
GO

