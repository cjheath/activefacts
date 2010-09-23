require 'dm-core'

class Boy
  include DataMapper::Resource

  property :boy_id, Serial	# Boy has Boy ID
  has 1, :girl	# Girl is going out with Boy
end

class Girl
  include DataMapper::Resource

  property :girl_id, Serial	# Girl has Girl ID
  property :boy_id, Integer	# maybe Girl is going out with Boy and Boy has Boy ID
  has 1, :boy	# Girl is going out with Boy
end

