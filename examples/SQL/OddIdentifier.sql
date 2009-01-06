CREATE TABLE ThingSequence (
	ThingID                                 AutoCounter NOT NULL,
	Ordinal                                 SignedInteger(32) NOT NULL,
	Text                                    VariableLengthText NULL,
	UNIQUE(ThingID, Text)
)
GO

