CREATE TABLE Claim (
	-- Claim has Claim ID,
	ClaimID                                 int IDENTITY NOT NULL,
	-- maybe Claim concerns Incident and maybe Incident occurred on Date Time,
	IncidentDateTime                        datetime NULL,
	PRIMARY KEY(ClaimID)
)
GO

CREATE TABLE VehicleIncident (
	-- maybe Vehicle Incident occured while Driver was in charge and Driver has Driver Name,
	DriverName                              varchar NULL,
	-- Vehicle Incident is a kind of Incident and Claim has Claim ID,
	IncidentID                              int IDENTITY NOT NULL,
	PRIMARY KEY(IncidentID),
	FOREIGN KEY (IncidentID) REFERENCES Claim (ClaimID)
)
GO

