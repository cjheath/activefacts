require 'dm-core'

class Playing
  include DataMapper::Resource

  property :person_name, String, :required => true, :key => true	# Playing is where Person plays Game and Person has Person Name
  property :game_code, String, :required => true, :key => true	# Playing is where Person plays Game and Game has Game Code
end

