require 'dm-core'

class Entrant
  include DataMapper::Resource

  property :entrant_id, Serial	# Entrant has Entrant ID
  has n, :entrant_given_name, 'EntrantGivenName'	# Entrant has Given Name
end

class Competitor < Entrant
  property :family_name, String, :required => true	# Competitor has Family Name
end

class EntrantGivenName
  include DataMapper::Resource

  property :entrant_id, Integer, :key => true	# Entrant Given Name is where Entrant has Given Name and Entrant has Entrant ID
  belongs_to :entrant	# Entrant is involved in Entrant Given Name
  property :given_name, String, :key => true	# Entrant Given Name is where Entrant has Given Name
end

class Team < Entrant
  property :team_id, Serial	# Team has Team ID
end

