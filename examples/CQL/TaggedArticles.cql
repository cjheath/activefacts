vocabulary TaggedArticles;

/*
 * Value Types
 */
ArticleID is defined as SignedInteger(32);
Tag is defined as VariableLengthText();

/*
 * Fact Types
 */
Tagging is where
	ArticleID has Tag,
	Tag applies to ArticleID;

