vocabulary TaggedArticles;

/*
 * Value Types
 */
ArticleID is written as SignedInteger(32);
Tag is written as VariableLengthText();

/*
 * Fact Types
 */
Tagging is where
	ArticleID has Tag,
	Tag applies to ArticleID;

