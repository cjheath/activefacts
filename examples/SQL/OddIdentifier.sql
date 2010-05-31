CREATE TABLE ThingSequence (
	-- Thing Sequence is where Thing has Ordinal occurrence,
	Ordinal                                 int NOT NULL,
	-- Thing Sequence has Text,
	Text                                    varchar NOT NULL,
	-- Thing Sequence is where Thing has Ordinal occurrence and Thing has Thing ID,
	ThingID                                 int NOT NULL,
	PRIMARY KEY(ThingID, Text),
	UNIQUE(ThingID, Ordinal)
)
GO

