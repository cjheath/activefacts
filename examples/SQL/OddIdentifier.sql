CREATE TABLE ThingSequence (
	ThingID                                 int NOT NULL,
	Ordinal                                 int NOT NULL,
	Text                                    varchar NULL,
	UNIQUE(ThingID, Text)
)
GO

