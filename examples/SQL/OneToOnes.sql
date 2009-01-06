CREATE TABLE Boy (
	BoyID                                   AutoCounter NOT NULL,
	PRIMARY KEY(BoyID)
)
GO

CREATE TABLE Girl (
	GirlID                                  AutoCounter NOT NULL,
	BoyID                                   AutoCounter NULL,
	PRIMARY KEY(GirlID)
)
GO

