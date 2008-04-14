require 'activefacts/api'

module TaggedArticles

  class ArticleID < SignedInteger
    value_type :length => 32
  end

  class Tag < String
    value_type 
  end

  class Tagging
    identified_by :tag, :article_i_d
    has_one :article_i_d
    has_one :tag
  end

end
