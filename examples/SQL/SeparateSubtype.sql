CREATE TABLE Claim (
	ClaimID	int NOT NULL,
	VehicleIncidentClaimID	int NULL,	-- Wrong absorption into identifying role
	UNIQUE(ClaimID)
)
GO

CREATE TABLE VehicleIncident (			-- Should absorb ClaimId here
	DriverName	varchar NULL,
	UNIQUE(IncidentClaimID)
)
GO
