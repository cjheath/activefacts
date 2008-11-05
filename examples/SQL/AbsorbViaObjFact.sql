CREATE TABLE PersonPlaysGame (
	Person_Name	varchar NOT NULL,
	Game_Code	Game_Code NOT NULL,
	UNIQUE(Person_Name, Game_Code)
)
GO

