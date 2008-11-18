vocabulary Blog;

/*
 * Value Types
 */
AuthorId is defined as AutoCounter();
CommentId is defined as AutoCounter();
Name is defined as VariableLengthText(64);
Ordinal is defined as UnsignedInteger(32);
PostId is defined as AutoCounter();
Style is defined as VariableLengthText(20);
Text is defined as LargeLengthText();
TopicId is defined as AutoCounter();

/*
 * Entity Types
 */
Author is identified by its Id;
author-Name is of at most one Author,
	Author is called exactly one Name;

Comment is identified by its Id;
Author wrote Comment,
	Comment was written by exactly one Author;

Content is identified by Style and Text where
	Content is of at most one Style,
	Content has exactly one Text,
	Text is of Content;
Content provides text of at most one Comment,
	Comment consists of exactly one text-Content;

Post is identified by its Id;
Post was written by exactly one Author;
Paragraph is where
	Post includes Ordinal paragraph;
Content is of at most one Paragraph,
	Paragraph contains exactly one Content;
Paragraph has Comment,
	Comment is on exactly one Paragraph;

Topic is identified by its Id;
Post belongs to exactly one Topic,
	Topic contains Post;
Topic belongs to at most one parent-Topic [acyclic];
Topic is called exactly one topic-Name,
	Name is of at most one Topic;

/*
 * Constraints:
 */
for each Content exactly one of these holds:
	Content provides text of Comment,
	Content is of Paragraph;
