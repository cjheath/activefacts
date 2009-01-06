CREATE TABLE Tagging (
	ArticleID                               SignedInteger(32) NOT NULL,
	Tag                                     VariableLengthText NOT NULL,
	PRIMARY KEY(ArticleID, Tag)
)
GO

