vocabulary TaggedArticles;

/*
 * Value Types
 */
ArticleID = SignedInteger(32);
Tag = VariableLengthText();

/*
 * Fact Types
 */
Tagging = ArticleID has Tag,
	Tag applies to ArticleID;

