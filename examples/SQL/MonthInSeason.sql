CREATE TABLE Month (
	MonthValue	varchar NOT NULL,
	Season	varchar NULL,
	PRIMARY KEY(MonthValue)
)
GO

CREATE TABLE Occurrence (
	EventId	int NOT NULL,
	Month	varchar NOT NULL,
	PRIMARY KEY(EventId, Month),
	FOREIGN KEY(Month)
	REFERENCES Month(MonthValue)
)
GO

