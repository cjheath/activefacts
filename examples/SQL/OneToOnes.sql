CREATE TABLE Boy (
	-- Boy has BoyID,
	BoyID                                   int IDENTITY NOT NULL,
	PRIMARY KEY(BoyID)
)
GO

CREATE TABLE Girl (
	-- Girl has GirlID,
	GirlID                                  int IDENTITY NOT NULL,
	-- maybe Girl is going out with Boy and Boy has BoyID,
	BoyID                                   int NULL,
	PRIMARY KEY(GirlID),
	FOREIGN KEY (BoyID) REFERENCES Boy (BoyID)
)
GO

