require 'activefacts/api'

module ::Blog

  class AuthorId < AutoCounter
    value_type 
  end

  class CommentId < AutoCounter
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
    one_to_one :author_name, Name               # See Name.author_as_author_name
  end

  class Comment
    identified_by :comment_id
    has_one :author                             # See Author.all_comment
    one_to_one :comment_id                      # See CommentId.comment
    has_one :content                            # See Content.all_comment
    has_one :paragraph                          # See Paragraph.all_comment
  end

  class Content
    identified_by :style, :text
    has_one :style                              # See Style.all_content
    has_one :text                               # See Text.all_content
  end

  class Post
    identified_by :post_id
    has_one :author                             # See Author.all_post
    one_to_one :post_id                         # See PostId.post
    has_one :topic                              # See Topic.all_post
  end

  class Paragraph
    identified_by :post, :ordinal
    has_one :ordinal                            # See Ordinal.all_paragraph
    has_one :post                               # See Post.all_paragraph
    has_one :content                            # See Content.all_paragraph
  end

  class Topic
    identified_by :topic_id
    has_one :parent_topic, Topic                # See Topic.all_topic_as_parent_topic
    one_to_one :topic_id                        # See TopicId.topic
    one_to_one :topic_name, Name                # See Name.topic_as_topic_name
  end

end
