require 'activefacts/api'

module TaggedArticles

  class ArticleID < SignedInteger
    value_type :length => 32
  end

  class Tag < String
    value_type 
  end

  class Tagging
    identified_by :article_id, :tag
    has_one :article_id, ArticleID              # See ArticleID.all_tagging_by_article_id
    has_one :tag                                # See Tag.all_tagging
  end

end
