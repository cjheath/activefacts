CREATE TABLE Author (
	AuthorId	int NOT NULL,
	AuthorName	varchar(64) NOT NULL,
	UNIQUE(AuthorId)
)
GO

CREATE TABLE Comment (
	CommentId	int NOT NULL,
	AuthorId	int NOT NULL,
	ContentStyle	varchar(20) NULL,
	ContentText	LargeLengthText NOT NULL,
	ParagraphOrdinal	int NOT NULL,
	ParagraphPostId	int NOT NULL,
	UNIQUE(CommentId),
	FOREIGN KEY(AuthorId)
	REFERENCES Author(AuthorId)
)
GO

CREATE TABLE Paragraph (
	Ordinal	int NOT NULL,
	PostId	int NOT NULL,
	ContentStyle	varchar(20) NULL,
	ContentText	LargeLengthText NOT NULL,
	UNIQUE(PostId, Ordinal)
)
GO

CREATE TABLE Post (
	PostId	int NOT NULL,
	AuthorId	int NOT NULL,
	TopicId	int NOT NULL,
	UNIQUE(PostId),
	FOREIGN KEY(AuthorId)
	REFERENCES Author(AuthorId)
)
GO

CREATE TABLE Topic (
	TopicId	int NOT NULL,
	ParentTopicId	int NULL,
	TopicName	varchar(64) NOT NULL,
	UNIQUE(TopicId),
	FOREIGN KEY(ParentTopicId)
	REFERENCES Topic(TopicId)
)
GO

ALTER TABLE Comment
	ADD FOREIGN KEY(ParagraphPostId, ParagraphOrdinal)
	REFERENCES Paragraph(PostId, Ordinal)
GO

ALTER TABLE Paragraph
	ADD FOREIGN KEY(PostId)
	REFERENCES Post(PostId)
GO

ALTER TABLE Post
	ADD FOREIGN KEY(TopicId)
	REFERENCES Topic(TopicId)
GO

