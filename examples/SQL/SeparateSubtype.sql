CREATE TABLE Claim (
	IncidentDateTime                        datetime NULL,
	ClaimID                                 int IDENTITY NOT NULL,
	PRIMARY KEY(ClaimID)
)
GO

CREATE TABLE VehicleIncident (
	IncidentID                              int IDENTITY NOT NULL,
	DriverName                              varchar NULL,
	PRIMARY KEY(IncidentID),
	FOREIGN KEY (IncidentID) REFERENCES Claim (ClaimID)
)
GO

