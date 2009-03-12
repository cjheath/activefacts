CREATE TABLE Author (
	-- Author has AuthorId,
	AuthorId                                int IDENTITY NOT NULL,
	-- author-Name is of Author,
	AuthorName                              varchar(64) NOT NULL,
	PRIMARY KEY(AuthorId),
	UNIQUE(AuthorName)
)
GO

CREATE TABLE Comment (
	-- Author wrote Comment and Author has AuthorId,
	AuthorId                                int NOT NULL,
	-- Comment has CommentId,
	CommentId                               int IDENTITY NOT NULL,
	-- Content provides text of Comment and maybe Content is of Style,
	ContentStyle                            varchar(20) NULL,
	-- Content provides text of Comment and Content has Text,
	ContentText                             text NOT NULL,
	-- Paragraph has Comment and Paragraph is where Post includes Ordinal paragraph,
	ParagraphOrdinal                        int NOT NULL,
	-- Paragraph has Comment and Paragraph is where Post includes Ordinal paragraph and Post has PostId,
	ParagraphPostId                         int NOT NULL,
	PRIMARY KEY(CommentId),
	FOREIGN KEY (AuthorId) REFERENCES Author (AuthorId)
)
GO

CREATE TABLE Paragraph (
	-- Content is of Paragraph and maybe Content is of Style,
	ContentStyle                            varchar(20) NULL,
	-- Content is of Paragraph and Content has Text,
	ContentText                             text NOT NULL,
	-- Paragraph is where Post includes Ordinal paragraph,
	Ordinal                                 int NOT NULL,
	-- Paragraph is where Post includes Ordinal paragraph and Post has PostId,
	PostId                                  int NOT NULL,
	PRIMARY KEY(PostId, Ordinal)
)
GO

CREATE TABLE Post (
	-- Post was written by Author and Author has AuthorId,
	AuthorId                                int NOT NULL,
	-- Post has PostId,
	PostId                                  int IDENTITY NOT NULL,
	-- Post belongs to Topic and Topic has TopicId,
	TopicId                                 int NOT NULL,
	PRIMARY KEY(PostId),
	FOREIGN KEY (AuthorId) REFERENCES Author (AuthorId)
)
GO

CREATE TABLE Topic (
	-- maybe Topic belongs to parent-Topic and Topic has TopicId,
	ParentTopicId                           int NULL,
	-- Topic has TopicId,
	TopicId                                 int IDENTITY NOT NULL,
	-- Topic is called topic-Name,
	TopicName                               varchar(64) NOT NULL,
	PRIMARY KEY(TopicId),
	UNIQUE(TopicName),
	FOREIGN KEY (ParentTopicId) REFERENCES Topic (TopicId)
)
GO

ALTER TABLE Comment
	ADD FOREIGN KEY (ParagraphOrdinal, ParagraphPostId) REFERENCES Paragraph (Ordinal, PostId)
GO

ALTER TABLE Paragraph
	ADD FOREIGN KEY (PostId) REFERENCES Post (PostId)
GO

ALTER TABLE Post
	ADD FOREIGN KEY (TopicId) REFERENCES Topic (TopicId)
GO

