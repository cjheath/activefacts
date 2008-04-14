require 'activefacts/api'

module Genealogy

  class Address < String
    value_type :length => 128
  end

  class Certificate < String
    value_type :length => 64
  end

  class Day < UnsignedInteger
    value_type :length => 32
    # REVISIT: Day has restricted values
  end

  class Email < String
    value_type :length => 64
  end

  class EventID < AutoCounter
    value_type 
  end

  class EventLocation < String
    value_type :length => 128
  end

  class EventRoleName < String
    value_type 
    # REVISIT: EventRoleName has restricted values
  end

  class EventTypeID < AutoCounter
    value_type 
  end

  class EventTypeName < String
    value_type :length => 16
    # REVISIT: EventTypeName has restricted values
  end

  class Gender < FixedLengthText
    value_type :length => 1
    # REVISIT: Gender has restricted values
  end

  class Month < UnsignedInteger
    value_type :length => 32
    # REVISIT: Month has restricted values
  end

  class Name < String
    value_type :length => 128
  end

  class Occupation < String
    value_type :length => 128
  end

  class Official < String
    value_type :length => 64
  end

  class PersonID < AutoCounter
    value_type 
  end

  class Picture < PictureRawData
    value_type :length => 20
  end

  class RoleID < AutoCounter
    value_type 
  end

  class SourceID < AutoCounter
    value_type 
  end

  class SourceName < String
    value_type :length => 128
  end

  class UserID < AutoCounter
    value_type 
  end

  class Year < UnsignedInteger
    value_type :length => 32
  end

  class Event
    identified_by :event_i_d
    one_to_one :event_i_d
    has_one :event_location
    has_one :certificate
    has_one :official
    has_one :event_type
    has_one :event_date
  end

  class EventDate
    identified_by :year_min, :year_max, :month, :day
    has_one :day
    has_one :year_min, Year
    has_one :year_max, Year
    has_one :month
  end

  class EventType
    identified_by :event_type_i_d
    one_to_one :event_type_name
    one_to_one :event_type_i_d
  end

  class Person
    identified_by :person_i_d
    one_to_one :person_i_d
    has_one :gender
    has_one :given_name, Name
    has_one :family_name, Name
    has_one :occupation
    has_one :address
    has_one :preferred_picture, Picture
    has_one :email
  end

  class Role
    identified_by :role_i_d
    one_to_one :role_i_d
    one_to_one :event_role_name
  end

  class Source
    identified_by :source_i_d
    one_to_one :source_name
    one_to_one :source_i_d
    has_one :user
  end

  class Participation
    identified_by :event, :role, :person, :source
    has_one :source
    has_one :person
    has_one :event
    has_one :role
  end

  class User
    identified_by :user_i_d
    one_to_one :user_i_d
    has_one :email
  end

  class Friend
    identified_by :other_user, :user
    has_one :user
    has_one :other_user, User
    maybe :is_confirmed
  end

end
