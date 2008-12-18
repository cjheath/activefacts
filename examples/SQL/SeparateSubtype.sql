CREATE TABLE Claim (
	ClaimID	int NOT NULL,
	VehicleIncidentClaimID	int NULL,	-- Wrong absorption into identifying role
	PRIMARY KEY(ClaimID)
)
GO

CREATE TABLE VehicleIncident (			-- Should absorb ClaimId here
	DriverName	varchar NULL,
	PRIMARY KEY(IncidentClaimID)
)
GO
