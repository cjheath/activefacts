CREATE TABLE Topic (
	ParentTopicId	int NULL,
	TopicId	int NOT NULL,
	TopicName	varchar(64) NOT NULL,
	UNIQUE(TopicId)
)
GO

CREATE TABLE Post (
	TopicId	int NOT NULL,
	AuthorId	int NOT NULL,
	PostId	int NOT NULL,
	UNIQUE(PostId)
)
GO

CREATE TABLE Author (
	AuthorName	varchar(64) NOT NULL,
	AuthorId	int NOT NULL,
	UNIQUE(AuthorId)
)
GO

CREATE TABLE Comment (
	ContentText	Text NOT NULL,
	ContentStyle	varchar(20) NULL,
	AuthorId	int NOT NULL,
	CommentId	int NOT NULL,
	ParagraphPostId	int NOT NULL,
	ParagraphOrdinal	int NOT NULL,
	UNIQUE(CommentId)
)
GO

CREATE TABLE Paragraph (
	PostId	int NOT NULL,
	ContentText	Text NOT NULL,
	ContentStyle	varchar(20) NULL,
	Ordinal	int NOT NULL,
	UNIQUE(PostId, Ordinal)
)
GO

