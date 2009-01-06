CREATE TABLE Month (
	Season                                  varchar NULL,
	MonthValue                              varchar NOT NULL,
	PRIMARY KEY(MonthValue)
)
GO

CREATE TABLE Occurrence (
	EventId                                 int NOT NULL,
	MonthValue                              varchar NOT NULL,
	PRIMARY KEY(EventId, MonthValue),
	FOREIGN KEY (MonthValue) REFERENCES Month (MonthValue)
)
GO

