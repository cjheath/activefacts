require 'dm-core'
require 'dm-constraints'

class Comparison
  include DataMapper::Resource

  property :comparison_id, Serial	# Comparison has Comparison Id
  property :larger_ordinal, Serial	# Comparison is where Ordinal comes before larger-Ordinal
  property :ordinal, Serial	# Comparison is where Ordinal comes before larger-Ordinal
end

