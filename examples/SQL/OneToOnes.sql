CREATE TABLE Boy (
	BoyID	int NOT NULL,
	GirlID	int NULL,			-- Shouldn't be both this
	PRIMARY KEY(BoyID)
)
GO

CREATE TABLE Girl (
	GirlID	int NOT NULL,
	BoyID	int NULL,			-- and this
	PRIMARY KEY(GirlID),
	FOREIGN KEY(BoyID)
	REFERENCES Boy(BoyID)
)
GO

ALTER TABLE Boy
	ADD FOREIGN KEY(GirlID)
	REFERENCES Girl(GirlID)
GO

