vocabulary Blog;

/*
 * Value Types
 */
AuthorId is written as AutoCounter;
CommentId is written as AutoCounter;
Name is written as VariableLengthText(64);
Ordinal is written as UnsignedInteger(32);
PostId is written as AutoCounter;
Style is written as VariableLengthText(20);
Text is written as LargeLengthText;
TopicId is written as AutoCounter;

/*
 * Entity Types
 */
Author is identified by its Id;
author-Name is of at most one Author,
	Author is called one Name;

Comment is identified by its Id;
Author wrote Comment,
	Comment was written by one Author;

Content is identified by Style and Text where
	Content is of at most one Style,
	Content has one Text,
	Text is of Content;
Content provides text of Comment,
	Comment consists of one text-Content;

Post is identified by its Id;
Post was written by one Author;
Paragraph is where
	Post includes Ordinal paragraph;
Content is of Paragraph,
	Paragraph contains one Content;
Paragraph has Comment,
	Comment is on one Paragraph;

Topic is identified by its Id;
Post belongs to one Topic,
	Topic contains Post;
Topic belongs to at most one parent-Topic [acyclic];
Topic is called one topic-Name,
	Name is of at most one Topic;

/*
 * Constraints:
 */
for each Content exactly one of these holds:
	Content provides text of Comment,
	Content is of Paragraph;
