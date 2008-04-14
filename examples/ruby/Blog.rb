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
    one_to_one :author_id
    one_to_one :author_name, Name
  end

  class Comment
    identified_by :comment_id
    one_to_one :comment_id
    has_one :author
    has_one :paragraph
  end

  class Content
    identified_by :content_id
    has_one :text
    one_to_one :content_id
    one_to_one :comment
    has_one :style
  end

  class Post
    identified_by :post_id
    one_to_one :post_id
    has_one :topic
    has_one :author
  end

  class Paragraph
    identified_by :ordinal, :post
    has_one :ordinal
    has_one :post
    one_to_one :content
  end

  class Topic
    identified_by :topic_id
    one_to_one :topic_id
    one_to_one :name
    has_one :parent_topic, Topic
  end

end
