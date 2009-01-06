CREATE TABLE Party (
	Partyid                                 int IDENTITY NOT NULL,
	PartyMonikerPartyName                   varchar NULL,
	PartyMonikerAccuracyLevel               int NULL CHECK((PartyMonikerAccuracyLevel >= 1 AND PartyMonikerAccuracyLevel <= 5)),
	PersonDateYmd                           datetime NULL,
	PersonAttendingDoctorId                 int NULL,
	PersonDeathDateYmd                      datetime NULL,
	PRIMARY KEY(Partyid)
)
GO

