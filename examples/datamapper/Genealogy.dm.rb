require 'dm-core'
require 'dm-constraints'

class Event
  include DataMapper::Resource

  property :event_id, Serial	# Event has Event ID
  property :certificate, String, :length => 64	# maybe Event is certified by Certificate
  property :event_location, String, :length => 128	# maybe Event occurred at Event Location
  property :official, String, :length => 64	# maybe Event was confirmed by Official
  property :event_date_min_year, Integer	# maybe Event occurred on Event Date and maybe Event Date wasnt before min-Year
  property :event_date_max_year, Integer	# maybe Event occurred on Event Date and maybe Event Date wasnt after max-Year
  property :event_date_month, Integer	# maybe Event occurred on Event Date and maybe Event Date occurred in Month
  property :event_date_day, Integer	# maybe Event occurred on Event Date and maybe Event Date occurred on Day
  property :event_type_id, Integer	# maybe Event is of Event Type and Event Type has Event Type ID
  belongs_to :event_type, 'EventType'	# Event is of Event Type
  has n, :participation	# Person played Role in Event according to Source
end

class EventType
  include DataMapper::Resource

  property :event_type_id, Serial	# Event Type has Event Type ID
  property :event_type_name, String, :length => 16, :required => true	# Event Type is called Event Type Name
  has n, :event	# Event is of Event Type
end

class Friend
  include DataMapper::Resource

  property :user_id, Integer, :key => true	# Friend is where User is friend of other-User and User has User ID
  belongs_to :user	# User is involved in Friend
  property :other_user_id, Integer, :key => true	# Friend is where User is friend of other-User and User has User ID
  belongs_to :other_user, 'User', :child_key => [:other_user_id], :parent_key => [:user_id]	# other_User is involved in Friend
  property :is_confirmed, Boolean	# Friend is confirmed
end

class Participation
  include DataMapper::Resource

  property :person_id, Integer, :key => true	# Participation is where Person played Role in Event according to Source and Person has Person ID
  belongs_to :person	# Person is involved in Participation
  property :role_id, Integer, :key => true	# Participation is where Person played Role in Event according to Source and Role has Role ID
  belongs_to :role	# Role is involved in Participation
  property :event_id, Integer, :key => true	# Participation is where Person played Role in Event according to Source and Event has Event ID
  belongs_to :event	# Event is involved in Participation
  property :source_id, Integer, :key => true	# Participation is where Person played Role in Event according to Source and Source has Source ID
  belongs_to :source	# Source is involved in Participation
end

class Person
  include DataMapper::Resource

  property :person_id, Serial	# Person has Person ID
  property :address, String, :length => 128	# maybe Address is of Person
  property :email, String, :length => 64	# maybe Email is of Person
  property :occupation, String, :length => 128	# maybe Occupation is of Person
  property :gender, String, :length => 1	# maybe Person is of Gender
  property :family_name, String, :length => 128	# maybe Person is called family-Name
  property :given_name, String, :length => 128	# maybe given-Name is name of Person
  property :preferred_picture, String, :length => 20	# maybe preferred-Picture is of Person
  has n, :participation	# Person played Role in Event according to Source
end

class Role
  include DataMapper::Resource

  property :role_id, Serial	# Role has Role ID
  property :event_role_name, String, :required => true	# Role is called Event Role Name
  has n, :participation	# Person played Role in Event according to Source
end

class Source
  include DataMapper::Resource

  property :source_id, Serial	# Source has Source ID
  property :source_name, String, :length => 128, :required => true	# Source has Source Name
  property :user_id, Integer, :required => true	# User provided Source and User has User ID
  belongs_to :user	# User provided Source
  has n, :participation	# Person played Role in Event according to Source
end

class User
  include DataMapper::Resource

  property :user_id, Serial	# User has User ID
  property :email, String, :length => 64	# maybe Email is of User
  has n, :source	# User provided Source
  has n, :friend	# User is friend of other-User
  has n, :friend_as_other_user, 'Friend', :child_key => [:other_user_id], :parent_key => [:user_id]	# User is friend of other-User
end

