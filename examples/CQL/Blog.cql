vocabulary Blog;

/*
 * Value Types
 */
Author Id is written as Auto Counter;
Comment Id is written as Auto Counter;
Name is written as String(64);
Ordinal is written as Unsigned Integer(32);
Post Id is written as Auto Counter;
Style is written as String(20);
Text is written as Text;
Topic Id is written as Auto Counter;

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
Post was written by one Author,
	Author wrote Post;

Topic is identified by its Id;
Post belongs to one Topic,
	Topic contains Post;
Topic belongs to at most one parent-Topic [acyclic];
Topic is called one topic-Name,
	Name is of at most one Topic;

Paragraph is where
	Post includes Ordinal paragraph;
Content is of Paragraph,
	Paragraph contains one Content;
Paragraph has Comment,
	Comment is on one Paragraph;

/*
 * Constraints:
 */
either Content provides text of Comment or Content is of Paragraph but not both;
