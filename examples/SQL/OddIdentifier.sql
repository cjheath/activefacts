CREATE TABLE ThingSequence (
	-- ThingSequence is where Thing has Ordinal occurrence,
	Ordinal                                 int NOT NULL,
	-- ThingSequence has Text,
	Text                                    varchar NOT NULL,
	-- ThingSequence is where Thing has Ordinal occurrence and Thing has ThingID,
	ThingID                                 int NOT NULL,
	PRIMARY KEY(ThingID, Text),
	UNIQUE(ThingID, Ordinal)
)
GO

