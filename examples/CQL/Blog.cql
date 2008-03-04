vocabulary Blog;

/*
 * Value Types
 */
AuthorId = AutoCounter();
CommentId = AutoCounter();
ContentId = AutoCounter();
Name = VariableLengthText(64);
Ordinal = UnsignedInteger(32);
PostId = AutoCounter();
Style = VariableLengthText(20);
Text = LargeLengthText();
TopicId = AutoCounter();

/*
 * Entity Types
 */
Author = entity known by AuthorId:
	Author has exactly one AuthorId,
	AuthorId is of at most one Author;
Name is of at most one Author,
	Author is called exactly one Name;

Comment = entity known by CommentId:
	Comment has exactly one CommentId,
	CommentId is of at most one Comment;
Author wrote Comment,
	Comment was written by exactly one Author;

Content = entity known by ContentId:
	Content has exactly one ContentId,
	ContentId is of at most one Content;
Content has exactly one Text,
	Text is of Content;
text-Content provides text of at most one Comment,
	Comment consists of exactly one text-Content;
Content is of at most one Style;

Post = entity known by PostId:
	Post has exactly one PostId,
	PostId is of at most one Post;
Post was written by exactly one Author;

Topic = entity known by TopicId:
	Topic has exactly one TopicId,
	TopicId is of at most one Topic;
Topic is called exactly one topic-Name,
	topic-Name is of at most one Topic;
Post belongs to exactly one Topic;
Topic belongs to at most one parent-Topic [acyclic];

Paragraph = entity known by Ordinal and Post:
	Post includes Ordinal paragraph;
Paragraph has Comment,
	Comment is on exactly one Paragraph;
Paragraph contains exactly one Content;

/*
Constraints:
	InternalUniquenessConstraint7: in ParagraphContainsContent, each value (Content) may occur at most 1 time
 */
