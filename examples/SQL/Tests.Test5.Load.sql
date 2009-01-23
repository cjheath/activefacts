CREATE TABLE Party (
	-- maybe PartyMoniker is where Party is called PartyName and PartyMoniker has Accuracy and Accuracy has Accuracylevel,
	PartyMonikerAccuracyLevel               int NULL CHECK((PartyMonikerAccuracyLevel >= 1 AND PartyMonikerAccuracyLevel <= 5)),
	-- maybe PartyMoniker is where Party is called PartyName and PartyMoniker is where Party is called PartyName,
	PartyMonikerPartyName                   varchar NULL,
	-- Party has Partyid,
	Partyid                                 int IDENTITY NOT NULL,
	-- maybe Person is a subtype of Party and Death is where Person died and maybe Death occurred on death-Date and Date has ymd,
	PersonDeathDateYmd                      datetime NULL,
	-- maybe Person is a subtype of Party and Birth is where Person was born on Date and maybe Birth was assisted by attending-Doctor and Party has Partyid,
	PersonAttendingDoctorId                 int NULL,
	-- maybe Person is a subtype of Party and Birth is where Person was born on Date and Birth is where Person was born on Date and Date has ymd,
	PersonDateYmd                           datetime NULL,
	PRIMARY KEY(Partyid),
	FOREIGN KEY (PersonAttendingDoctorId) REFERENCES Party (Partyid)
)
GO

