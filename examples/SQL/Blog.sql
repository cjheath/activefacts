CREATE TABLE Author (
	AuthorId                                int IDENTITY NOT NULL,
	AuthorName                              varchar(64) NOT NULL,
	PRIMARY KEY(AuthorId)
)
GO

CREATE TABLE Comment (
	CommentId                               int IDENTITY NOT NULL,
	AuthorId                                int NOT NULL,
	ParagraphPostId                         int NOT NULL,
	ParagraphOrdinal                        int NOT NULL,
	ContentText                             text NOT NULL,
	ContentStyle                            varchar(20) NULL,
	PRIMARY KEY(CommentId),
	FOREIGN KEY (AuthorId) REFERENCES Author (AuthorId)
)
GO

CREATE TABLE Paragraph (
	PostId                                  int NOT NULL,
	Ordinal                                 int NOT NULL,
	ContentText                             text NOT NULL,
	ContentStyle                            varchar(20) NULL,
	PRIMARY KEY(PostId, Ordinal)
)
GO

CREATE TABLE Post (
	PostId                                  int IDENTITY NOT NULL,
	TopicId                                 int NOT NULL,
	AuthorId                                int NOT NULL,
	PRIMARY KEY(PostId),
	FOREIGN KEY (AuthorId) REFERENCES Author (AuthorId)
)
GO

CREATE TABLE Topic (
	TopicId                                 int IDENTITY NOT NULL,
	TopicName                               varchar(64) NOT NULL,
	ParentTopicId                           int NULL,
	PRIMARY KEY(TopicId),
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

