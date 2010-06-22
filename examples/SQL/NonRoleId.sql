CREATE TABLE Comparison (
	-- Comparison has Comparison Id,
	ComparisonId                            int IDENTITY NOT NULL,
	-- Comparison is where Ordinal comes before larger-Ordinal,
	LargerOrdinal                           int NOT NULL,
	-- Comparison is where Ordinal comes before larger-Ordinal,
	Ordinal                                 int NOT NULL,
	PRIMARY KEY(ComparisonId),
	UNIQUE(Ordinal, LargerOrdinal)
)
GO

