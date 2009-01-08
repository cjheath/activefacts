CREATE TABLE ThingSequence (
	-- ThingSequence is where Thing has Ordinal occurrence and Thing has ThingID,
	ThingID                                 int NOT NULL,
	-- ThingSequence is where Thing has Ordinal occurrence,
	Ordinal                                 int NOT NULL,
	-- maybe ThingSequence has Text,
	Text                                    varchar NULL,
	UNIQUE(ThingID, Text)
)
GO

