require 'dm-core'

class Comparison
  include DataMapper::Resource

  property :ordinal, Serial	# Comparison is where Ordinal comes before larger-Ordinal
  property :larger_ordinal, Serial	# Comparison is where Ordinal comes before larger-Ordinal
  property :comparison_id, Serial	# Comparison has Comparison Id
end

