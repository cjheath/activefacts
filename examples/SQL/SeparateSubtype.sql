CREATE TABLE Claim (
	-- Claim has Claim ID,
	ClaimID                                 int IDENTITY NOT NULL,
	-- maybe Claim concerns Incident and maybe Incident occurred on Date Time,
	IncidentDateTime                        datetime NULL,
	-- maybe Claim concerns Incident and maybe Witness saw Incident and Person has Person Name,
	IncidentWitnessName                     varchar NULL,
	PRIMARY KEY(ClaimID)
)
GO

CREATE TABLE Person (
	-- Person has Person Name,
	PersonName                              varchar NOT NULL,
	PRIMARY KEY(PersonName)
)
GO

CREATE TABLE VehicleIncident (
	-- maybe Vehicle Incident occured while Driver was in charge and Person has Person Name,
	DriverName                              varchar NULL,
	-- Vehicle Incident is a kind of Incident and Claim has Claim ID,
	IncidentID                              int NOT NULL,
	PRIMARY KEY(IncidentID),
	FOREIGN KEY (IncidentID) REFERENCES Claim (ClaimID),
	FOREIGN KEY (DriverName) REFERENCES Person (PersonName)
)
GO

ALTER TABLE Claim
	ADD FOREIGN KEY (IncidentWitnessName) REFERENCES Person (PersonName)
GO

