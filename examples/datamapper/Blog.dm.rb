require 'dm-core'
require 'dm-constraints'

class Author
  include DataMapper::Resource

  property :author_id, Serial	# Author has Author Id
  property :author_name, String, :length => 64, :required => true	# author-Name is of Author
  has n, :comment	# Author wrote Comment
  has n, :post	# Post was written by Author
end

class Comment
  include DataMapper::Resource

  property :author_id, Integer, :required => true	# Author wrote Comment and Author has Author Id
  belongs_to :author	# Author wrote Comment
  property :paragraph_ordinal, Integer, :required => true	# Paragraph has Comment and Paragraph is where Post includes Ordinal paragraph
  property :paragraph_post_id, Integer, :required => true	# Paragraph has Comment and Paragraph is where Post includes Ordinal paragraph and Post has Post Id
  belongs_to :paragraph, :child_key => [:paragraph_post_id, :paragraph_ordinal], :parent_key => [:post_id, :ordinal]	# Paragraph has Comment
  property :comment_id, Serial	# Comment has Comment Id
  property :content_style, String, :length => 20	# Content provides text of Comment and maybe Content is of Style
  property :content_text, Text, :required => true	# Content provides text of Comment and Content has Text
end

class Paragraph
  include DataMapper::Resource

  property :content_style, String, :length => 20	# Content is of Paragraph and maybe Content is of Style
  property :content_text, Text, :required => true	# Content is of Paragraph and Content has Text
  property :ordinal, Integer, :key => true	# Paragraph is where Post includes Ordinal paragraph
  property :post_id, Integer, :key => true	# Paragraph is where Post includes Ordinal paragraph and Post has Post Id
  belongs_to :post	# Post is involved in Paragraph
  has n, :comment, :child_key => [:paragraph_post_id, :paragraph_ordinal], :parent_key => [:post_id, :ordinal]	# Comment is involved in Paragraph
end

class Post
  include DataMapper::Resource

  property :author_id, Integer, :required => true	# Post was written by Author and Author has Author Id
  belongs_to :author	# Post was written by Author
  property :topic_id, Integer, :required => true	# Post belongs to Topic and Topic has Topic Id
  belongs_to :topic	# Post belongs to Topic
  property :post_id, Serial	# Post has Post Id
  has n, :paragraph	# Post includes Ordinal paragraph
end

class Topic
  include DataMapper::Resource

  property :topic_name, String, :length => 64, :required => true	# Topic is called topic-Name
  property :topic_id, Serial	# Topic has Topic Id
  property :parent_topic_id, Integer	# maybe Topic belongs to parent-Topic and Topic has Topic Id
  belongs_to :parent_topic, 'Topic', :child_key => [:parent_topic_id], :parent_key => [:topic_id]	# Topic belongs to parent-Topic
  has n, :post	# Post belongs to Topic
  has n, :topic_as_parent_topic, 'Topic', :child_key => [:parent_topic_id], :parent_key => [:topic_id]	# Topic belongs to parent-Topic
end

