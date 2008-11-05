CREATE TABLE PersonPlaysGame (
	Game_Code	FixedLengthText NOT NULL,
	Person_Name	varchar NOT NULL,
	UNIQUE(Person_Name, Game_Code)
)
GO

