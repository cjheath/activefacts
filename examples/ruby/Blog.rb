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

  class Text < ::Text
    value_type 
  end

  class TopicId < AutoCounter
    value_type 
  end

  class Author
    identified_by :author_id
    one_to_one :author_id, :mandatory => true   # See AuthorId.author
    one_to_one :author_name, :class => Name, :mandatory => true  # See Name.author_as_author_name
  end

  class Comment
    identified_by :comment_id
    has_one :author, :mandatory => true         # See Author.all_comment
    one_to_one :comment_id, :mandatory => true  # See CommentId.comment
    has_one :content, :mandatory => true        # See Content.all_comment
    has_one :paragraph, :mandatory => true      # See Paragraph.all_comment
  end

  class Content
    identified_by :style, :text
    has_one :style                              # See Style.all_content
    has_one :text, :mandatory => true           # See Text.all_content
  end

  class Post
    identified_by :post_id
    has_one :author, :mandatory => true         # See Author.all_post
    one_to_one :post_id, :mandatory => true     # See PostId.post
    has_one :topic, :mandatory => true          # See Topic.all_post
  end

  class Topic
    identified_by :topic_id
    has_one :parent_topic, :class => Topic      # See Topic.all_topic_as_parent_topic
    one_to_one :topic_id, :mandatory => true    # See TopicId.topic
    one_to_one :topic_name, :class => Name, :mandatory => true  # See Name.topic_as_topic_name
  end

  class Paragraph
    identified_by :post, :ordinal
    has_one :ordinal, :mandatory => true        # See Ordinal.all_paragraph
    has_one :post, :mandatory => true           # See Post.all_paragraph
    has_one :content, :mandatory => true        # See Content.all_paragraph
  end

end
