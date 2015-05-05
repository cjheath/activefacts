CREATE TABLE Claim (
	-- Claim has Claim ID,
	ClaimID                                 int IDENTITY NOT NULL,
	-- maybe Claim concerns Incident and maybe Incident occurred on Date Time,
	IncidentDateTime                        datetime NULL,
	-- maybe Claim concerns Incident and maybe Incident was independently witnessed by Witness and Witness is a kind of Person and Person has Person Name,
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
	-- maybe Vehicle Incident occurred while Driver was in charge and Driver is a kind of Person and Person has Person Name,
	DriverName                              varchar NULL,
	-- Vehicle Incident is a kind of Incident and Incident resulted in Claim and Claim has Claim ID,
	IncidentClaimID                         int NOT NULL,
	PRIMARY KEY(IncidentClaimID),
	FOREIGN KEY (IncidentClaimID) REFERENCES Claim (ClaimID),
	FOREIGN KEY (DriverName) REFERENCES Person (PersonName)
)
GO

ALTER TABLE Claim
	ADD FOREIGN KEY (IncidentWitnessName) REFERENCES Person (PersonName)
GO

