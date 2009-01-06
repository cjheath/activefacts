CREATE TABLE Boy (
	BoyID                                   int IDENTITY NOT NULL,
	PRIMARY KEY(BoyID)
)
GO

CREATE TABLE Girl (
	GirlID                                  int IDENTITY NOT NULL,
	BoyID                                   int NULL,
	PRIMARY KEY(GirlID),
	FOREIGN KEY (BoyID) REFERENCES Boy (BoyID)
)
GO

