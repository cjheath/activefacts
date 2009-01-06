CREATE TABLE Month (
	Season                                  VariableLengthText NULL,
	MonthValue                              VariableLengthText NOT NULL,
	PRIMARY KEY(MonthValue)
)
GO

CREATE TABLE Occurrence (
	EventId                                 AutoCounter NOT NULL,
	MonthValue                              VariableLengthText NOT NULL,
	PRIMARY KEY(EventId, MonthValue)
)
GO

