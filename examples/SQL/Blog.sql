CREATE TABLE Author (
	AuthorId                                AutoCounter NOT NULL,
	AuthorName                              VariableLengthText(64) NOT NULL,
	PRIMARY KEY(AuthorId)
)
GO

CREATE TABLE Comment (
	CommentId                               AutoCounter NOT NULL,
	AuthorId                                AutoCounter NOT NULL,
	ParagraphPostId                         AutoCounter NOT NULL,
	ParagraphOrdinal                        UnsignedInteger(32) NOT NULL,
	ContentText                             LargeLengthText NOT NULL,
	ContentStyle                            VariableLengthText(20) NULL,
	PRIMARY KEY(CommentId)
)
GO

CREATE TABLE Paragraph (
	PostId                                  AutoCounter NOT NULL,
	Ordinal                                 UnsignedInteger(32) NOT NULL,
	ContentText                             LargeLengthText NOT NULL,
	ContentStyle                            VariableLengthText(20) NULL,
	PRIMARY KEY(PostId, Ordinal)
)
GO

CREATE TABLE Post (
	PostId                                  AutoCounter NOT NULL,
	TopicId                                 AutoCounter NOT NULL,
	AuthorId                                AutoCounter NOT NULL,
	PRIMARY KEY(PostId)
)
GO

CREATE TABLE Topic (
	TopicId                                 AutoCounter NOT NULL,
	TopicName                               VariableLengthText(64) NOT NULL,
	ParentTopicId                           AutoCounter NULL,
	PRIMARY KEY(TopicId)
)
GO

