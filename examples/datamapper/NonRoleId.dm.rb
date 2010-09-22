require 'dm-core'

class Comparison
  include DataMapper::Resource

  property :ordinal, Serial, :required => true, :key => true	# Comparison is where Ordinal comes before larger-Ordinal
  property :larger_ordinal, Serial, :required => true, :key => true	# Comparison is where Ordinal comes before larger-Ordinal
  property :comparison_id, Serial, :required => true, :key => true	# Comparison has Comparison Id
end

