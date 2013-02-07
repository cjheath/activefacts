CREATE TABLE SomeString (
	-- Some String is long,
	IsLong                                  bit NULL,
	-- Some String has value,
	SomeStringValue                         varchar NOT NULL,
	UNIQUE(IsLong, SomeStringValue)
)
GO

