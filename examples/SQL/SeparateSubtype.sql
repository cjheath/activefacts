CREATE TABLE Incident (
	-- Claim concerns Incident and Claim has Claim ID,
	ClaimID                                 int IDENTITY NOT NULL,
	-- maybe Incident occurred on Date Time,
	DateTime                                datetime NULL,
	PRIMARY KEY(ClaimID),
	UNIQUE(ClaimID)
)
GO

CREATE TABLE VehicleIncident (
	-- maybe Vehicle Incident occured while Driver was in charge and Driver has Driver Name,
	DriverName                              varchar NULL,
	-- Vehicle Incident is a kind of Incident and Claim concerns Incident and Claim has Claim ID,
	IncidentClaimID                         int IDENTITY NOT NULL,
	PRIMARY KEY(IncidentClaimID),
	UNIQUE(IncidentClaimID),
	FOREIGN KEY (IncidentClaimID) REFERENCES Incident (ClaimID)
)
GO

