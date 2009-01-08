CREATE TABLE Claim (
	-- maybe Claim concerns Incident and maybe Incident occurred on DateTime,
	IncidentDateTime                        datetime NULL,
	-- Claim has ClaimID,
	ClaimID                                 int IDENTITY NOT NULL,
	PRIMARY KEY(ClaimID)
)
GO

CREATE TABLE VehicleIncident (
	-- VehicleIncident is a subtype of Incident and Claim has ClaimID,
	IncidentID                              int IDENTITY NOT NULL,
	-- maybe VehicleIncident occured while Driver was in charge and Driver has DriverName,
	DriverName                              varchar NULL,
	PRIMARY KEY(IncidentID),
	FOREIGN KEY (IncidentID) REFERENCES Claim (ClaimID)
)
GO

