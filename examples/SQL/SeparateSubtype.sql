CREATE TABLE Claim (
	IncidentDateTime                        DateAndTime NULL,
	ClaimID                                 AutoCounter NOT NULL,
	PRIMARY KEY(ClaimID)
)
GO

CREATE TABLE VehicleIncident (
	IncidentID                              AutoCounter NOT NULL,
	DriverName                              VariableLengthText NULL,
	PRIMARY KEY(IncidentID)
)
GO

