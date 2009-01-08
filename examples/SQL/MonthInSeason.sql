CREATE TABLE Month (
	-- maybe Month is in Season,
	Season                                  varchar NULL,
	-- Month has value,
	MonthValue                              varchar NOT NULL,
	PRIMARY KEY(MonthValue)
)
GO

CREATE TABLE Occurrence (
	-- Occurrence is where Event occurred in Month and Event has EventId,
	EventId                                 int NOT NULL,
	-- Occurrence is where Event occurred in Month and Month has value,
	MonthValue                              varchar NOT NULL,
	PRIMARY KEY(EventId, MonthValue),
	FOREIGN KEY (MonthValue) REFERENCES Month (MonthValue)
)
GO

