require 'activefacts/api'

module Blog

  class AuthorId < AutoCounter
    value_type 
  end

  class CommentId < AutoCounter
    value_type 
  end

  class ContentId < AutoCounter
    value_type 
  end

  class Name < String
    value_type :length => 64
  end

  class Ordinal < UnsignedInteger
    value_type :length => 32
  end

  class PostId < AutoCounter
    value_type 
  end

  class Style < String
    value_type :length => 20
  end

  class Text < LargeLengthText
    value_type 
  end

  class TopicId < AutoCounter
    value_type 
  end

  class Author
    identified_by :author_id
    one_to_one :author_id                       # See AuthorId.author
    one_to_one :author_name, Name               # See Name.author_by_author_name
  end

  class Comment
    identified_by :comment_id
    one_to_one :comment_id                      # See CommentId.comment
    has_one :author                             # See Author.all_comment
    has_one :paragraph                          # See Paragraph.all_comment
  end

  class Content
    identified_by :content_id
    has_one :text                               # See Text.all_content
    one_to_one :content_id                      # See ContentId.content
    one_to_one :comment                         # See Comment.content
    has_one :style                              # See Style.all_content
  end

  class Post
    identified_by :post_id
    one_to_one :post_id                         # See PostId.post
    has_one :topic                              # See Topic.all_post
    has_one :author                             # See Author.all_post
  end

  class Paragraph
    identified_by :ordinal, :post
    has_one :ordinal                            # See Ordinal.all_paragraph
    has_one :post                               # See Post.all_paragraph
    one_to_one :content                         # See Content.paragraph
  end

  class Topic
    identified_by :topic_id
    one_to_one :topic_id                        # See TopicId.topic
    one_to_one :topic_name, Name                # See Name.topic_by_topic_name
    has_one :parent_topic, Topic                # See Topic.all_topic_by_parent_topic
  end

end
