CREATE TABLE Tagging (
	-- Tagging is where ArticleID has Tag,
	ArticleID                               int NOT NULL,
	-- Tagging is where ArticleID has Tag,
	Tag                                     varchar NOT NULL,
	PRIMARY KEY(ArticleID, Tag)
)
GO

