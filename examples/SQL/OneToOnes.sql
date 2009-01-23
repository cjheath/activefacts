CREATE TABLE Boy (
	-- Boy has BoyID,
	BoyID                                   int IDENTITY NOT NULL,
	PRIMARY KEY(BoyID)
)
GO

CREATE TABLE Girl (
	-- maybe Girl is going out with Boy and Boy has BoyID,
	BoyID                                   int NULL,
	-- Girl has GirlID,
	GirlID                                  int IDENTITY NOT NULL,
	PRIMARY KEY(GirlID),
	FOREIGN KEY (BoyID) REFERENCES Boy (BoyID)
)
GO

CREATE VIEW dbo.Girl_BoyID (BoyID) WITH SCHEMABINDING AS
	SELECT BoyID FROM dbo.Girl
	WHERE	BoyID IS NOT NULL
GO

CREATE UNIQUE CLUSTERED INDEX IX_GirlByBoyID ON dbo.Girl_BoyID(BoyID)
GO

