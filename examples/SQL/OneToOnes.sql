CREATE TABLE Boy (
	BoyID	int NOT NULL,
	GirlID	int NULL,			-- Shouldn't be both this
	UNIQUE(BoyID)
)
GO

CREATE TABLE Claim (
	ClaimID	int NOT NULL,
	VehicleIncidentClaimID	int NULL,	-- Wrong absorption into identifying role
	UNIQUE(ClaimID)
)
GO

CREATE TABLE Girl (
	GirlID	int NOT NULL,
	BoyID	int NULL,			-- and this
	UNIQUE(GirlID),
	FOREIGN KEY(BoyID)
	REFERENCES Boy(BoyID)
)
GO

CREATE TABLE VehicleIncident (			-- Should absorb ClaimId here
	DriverName	varchar NULL,
	UNIQUE(IncidentClaimID)
)
GO

ALTER TABLE Boy
	ADD FOREIGN KEY(GirlID)
	REFERENCES Girl(GirlID)
GO

