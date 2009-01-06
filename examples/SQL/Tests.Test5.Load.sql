CREATE TABLE Party (
	Partyid                                 AutoCounter NOT NULL,
	PartyMonikerPartyName                   VariableLengthText NULL,
	PartyMonikerAccuracyLevel               SignedInteger(32) NULL CHECK(REVISIT: valid value),
	PersonDateYmd                           Date NULL,
	PersonAttendingDoctorId                 AutoCounter NULL,
	PersonDeathDateYmd                      Date NULL,
	PRIMARY KEY(Partyid)
)
GO

