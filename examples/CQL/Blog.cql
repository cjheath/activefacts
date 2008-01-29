vocabulary Blog;

/*
 * Value Types
 */
AuthorId = AutoCounter();
CommentId = AutoCounter();
Name = VariableLengthText(64);
PostId = AutoCounter();
SectionId = AutoCounter();
Sequence = UnsignedInteger(32);
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

Post = entity known by PostId:
	Post has exactly one PostId,
	PostId is of at most one Post;
Post was written by exactly one Author;
ParagraphComment = paragraph-Sequence in Post has Comment,
	Comment on Post applies to at most one paragraph-Sequence,
	each Comment on some Post applies to some paragraph-Sequence;

Section = entity known by SectionId:
	Section has exactly one SectionId,
	SectionId is of at most one Section;
Section has exactly one Text,
	Text is of Section;
PostSectionSequence = Sequence in Post contains at most one Section;
text-Section provides text of at most one Comment,
	Comment consists of exactly one text-Section;
Section is of at most one Style;

Topic = entity known by TopicId:
	Topic has exactly one TopicId,
	TopicId is of at most one Topic;
Topic is called exactly one topic-Name,
	topic-Name is of at most one Topic;
Post belongs to exactly one Topic;
Topic belongs to at most one parent-Topic [acyclic];

/*
Constraints:
	MandatoryExclusionConstraint ExclusiveOrConstraint1 over PostSectionSequence(Section), SectionProvidesTextOfComment(Section)
 */
