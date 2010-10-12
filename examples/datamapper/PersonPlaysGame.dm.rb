require 'dm-core'
require 'dm-constraints'

class Playing
  include DataMapper::Resource

  property :person_name, String, :key => true	# Playing is where Person plays Game and Person has Person Name
  property :game_code, String, :key => true	# Playing is where Person plays Game and Game has Game Code
end

