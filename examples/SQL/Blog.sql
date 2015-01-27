CREATE TABLE Author (
	-- Author has Author Id,
	AuthorId                                int IDENTITY NOT NULL,
	-- Author is called Name,
	AuthorName                              varchar(64) NOT NULL,
	PRIMARY KEY(AuthorId),
	UNIQUE(AuthorName)
)
GO

CREATE TABLE Comment (
	-- Comment was written by Author and Author has Author Id,
	AuthorId                                int NOT NULL,
	-- Comment has Comment Id,
	CommentId                               int IDENTITY NOT NULL,
	-- Comment consists of text-Content and maybe Content is of Style,
	ContentStyle                            varchar(20) NULL,
	-- Comment consists of text-Content and Content has Text,
	ContentText                             text NOT NULL,
	-- Comment is on Paragraph and Paragraph (in which Post includes Ordinal paragraph) involves Ordinal,
	ParagraphOrdinal                        int NOT NULL,
	-- Comment is on Paragraph and Paragraph (in which Post includes Ordinal paragraph) and Post has Post Id,
	ParagraphPostId                         int NOT NULL,
	PRIMARY KEY(CommentId),
	FOREIGN KEY (AuthorId) REFERENCES Author (AuthorId)
)
GO

CREATE TABLE Paragraph (
	-- Paragraph contains Content and maybe Content is of Style,
	ContentStyle                            varchar(20) NULL,
	-- Paragraph contains Content and Content has Text,
	ContentText                             text NOT NULL,
	-- Paragraph (in which Post includes Ordinal paragraph) involves Ordinal,
	Ordinal                                 int NOT NULL,
	-- Paragraph (in which Post includes Ordinal paragraph) and Post has Post Id,
	PostId                                  int NOT NULL,
	PRIMARY KEY(PostId, Ordinal)
)
GO

CREATE TABLE Post (
	-- Post was written by Author and Author has Author Id,
	AuthorId                                int NOT NULL,
	-- Post has Post Id,
	PostId                                  int IDENTITY NOT NULL,
	-- Post belongs to Topic and Topic has Topic Id,
	TopicId                                 int NOT NULL,
	PRIMARY KEY(PostId),
	FOREIGN KEY (AuthorId) REFERENCES Author (AuthorId)
)
GO

CREATE TABLE Topic (
	-- maybe Topic belongs to parent-Topic and Topic has Topic Id,
	ParentTopicId                           int NULL,
	-- Topic has Topic Id,
	TopicId                                 int IDENTITY NOT NULL,
	-- Topic is called topic-Name,
	TopicName                               varchar(64) NOT NULL,
	PRIMARY KEY(TopicId),
	UNIQUE(TopicName),
	FOREIGN KEY (ParentTopicId) REFERENCES Topic (TopicId)
)
GO

ALTER TABLE Comment
	ADD FOREIGN KEY (ParagraphPostId, ParagraphOrdinal) REFERENCES Paragraph (PostId, Ordinal)
GO

ALTER TABLE Paragraph
	ADD FOREIGN KEY (PostId) REFERENCES Post (PostId)
GO

ALTER TABLE Post
	ADD FOREIGN KEY (TopicId) REFERENCES Topic (TopicId)
GO

