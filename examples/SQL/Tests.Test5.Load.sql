CREATE TABLE Party (
	Partyid	int NOT NULL,
	PartyMonikerAccuracyLevel	int NULL,
	PartyMonikerPartyName	varchar NOT NULL,
	PersonBirthAttendingDoctorId	int NULL,
	PersonBirthDateYmd	datetime NULL,
	PersonDeathDeathDateYmd	datetime NULL,
	PersonDied	bit NULL,
	PRIMARY KEY(Partyid)
)
GO

