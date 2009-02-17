require 'activefacts/api'

module ::Genealogy

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
    identified_by :event_id
    has_one :certificate                        # See Certificate.all_event
    has_one :event_date                         # See EventDate.all_event
    one_to_one :event_id, EventID               # See EventID.event
    has_one :event_location                     # See EventLocation.all_event
    has_one :event_type                         # See EventType.all_event
    has_one :official                           # See Official.all_event
  end

  class EventDate
    identified_by :min_year, :max_year, :month, :day
    has_one :day                                # See Day.all_event_date
    has_one :max_year, Year                     # See Year.all_event_date_as_max_year
    has_one :min_year, Year                     # See Year.all_event_date_as_min_year
    has_one :month                              # See Month.all_event_date
  end

  class EventType
    identified_by :event_type_id
    one_to_one :event_type_id, EventTypeID      # See EventTypeID.event_type
    one_to_one :event_type_name                 # See EventTypeName.event_type
  end

  class Person
    identified_by :person_id
    has_one :address                            # See Address.all_person
    has_one :email                              # See Email.all_person
    has_one :family_name, Name                  # See Name.all_person_as_family_name
    has_one :gender                             # See Gender.all_person
    has_one :given_name, Name                   # See Name.all_person_as_given_name
    has_one :occupation                         # See Occupation.all_person
    one_to_one :person_id, PersonID             # See PersonID.person
    has_one :preferred_picture, Picture         # See Picture.all_person_as_preferred_picture
  end

  class Role
    identified_by :role_id
    one_to_one :event_role_name                 # See EventRoleName.role
    one_to_one :role_id, RoleID                 # See RoleID.role
  end

  class Source
    identified_by :source_id
    one_to_one :source_id, SourceID             # See SourceID.source
    one_to_one :source_name                     # See SourceName.source
    has_one :user                               # See User.all_source
  end

  class Participation
    identified_by :person, :role, :event, :source
    has_one :event                              # See Event.all_participation
    has_one :person                             # See Person.all_participation
    has_one :role                               # See Role.all_participation
    has_one :source                             # See Source.all_participation
  end

  class User
    identified_by :user_id
    has_one :email                              # See Email.all_user
    one_to_one :user_id, UserID                 # See UserID.user
  end

  class Friend
    identified_by :user, :other_user
    has_one :other_user, User                   # See User.all_friend_as_other_user
    has_one :user                               # See User.all_friend
    maybe :is_confirmed
  end

end
