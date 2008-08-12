vocabulary Blog;

/*
 * Value Types
 */
AuthorId is defined as AutoCounter();
CommentId is defined as AutoCounter();
ContentId is defined as AutoCounter();
Name is defined as VariableLengthText(64);
Ordinal is defined as UnsignedInteger(32);
PostId is defined as AutoCounter();
Style is defined as VariableLengthText(20);
Text is defined as LargeLengthText();
TopicId is defined as AutoCounter();

/*
 * Entity Types
 */
Author is identified by AuthorId where
	Author has exactly one AuthorId,
	AuthorId is of at most one Author;
author-Name is of at most one Author,
	Author is called exactly one Name;

Comment is identified by CommentId where
	Comment has exactly one CommentId,
	CommentId is of at most one Comment;
Author wrote Comment,
	Comment was written by exactly one Author;

Content is identified by ContentId where
	Content has exactly one ContentId,
	ContentId is of at most one Content;
Content provides text of at most one Comment,
	Comment consists of exactly one text-Content;
Content is of at most one Style;
Content has exactly one Text,
	Text is of Content;

Post is identified by PostId where
	Post has exactly one PostId,
	PostId is of at most one Post;
Post was written by exactly one Author;
Paragraph is where
	Post includes Ordinal paragraph;
Content is of at most one Paragraph,
	Paragraph contains exactly one Content;
Paragraph has Comment,
	Comment is on exactly one Paragraph;

Topic is identified by TopicId where
	Topic has exactly one TopicId,
	TopicId is of at most one Topic;
Post belongs to exactly one Topic,
	Topic contains Post;
Topic belongs to at most one parent-Topic [acyclic];
Topic is called exactly one topic-Name,
	Name is of at most one Topic;

/*
 * Constraints:
for each Content exactly one of these holds:
	Content provides text of Comment,
	Content is of Paragraph;
 */
