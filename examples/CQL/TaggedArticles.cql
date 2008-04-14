vocabulary TaggedArticles;

/*
 * Value Types
 */
ArticleID = SignedInteger(32);
Tag = VariableLengthText();

/*
 * Entity Types
 */
/*
 * Fact Types
 */
Tagging = ArticleID has Tag,
	Tag applies to ArticleID;

