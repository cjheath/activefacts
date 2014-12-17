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
    restrict 1..31
  end

  class Email < String
    value_type :length => 64
  end

  class EventID < AutoCounter
    value_type 
    one_to_one :event                           # See Event.event_id
  end

  class EventLocation < String
    value_type :length => 128
  end

  class EventRoleName < String
    value_type 
    restrict 'Celebrant', 'Father', 'Husband', 'Mother', 'Subject', 'Wife'
    one_to_one :role                            # See Role.event_role_name
  end

  class EventTypeID < AutoCounter
    value_type 
    one_to_one :event_type                      # See EventType.event_type_id
  end

  class EventTypeName < String
    value_type :length => 16
    restrict 'Birth', 'Burial', 'Christening', 'Death', 'Divorce', 'Marriage'
    one_to_one :event_type                      # See EventType.event_type_name
  end

  class Gender < Char
    value_type :length => 1
    restrict 'F', 'M'
  end

  class Month < UnsignedInteger
    value_type :length => 32
    restrict 1..12
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
    one_to_one :person                          # See Person.person_id
  end

  class Picture < Image
    value_type 
  end

  class RoleID < AutoCounter
    value_type 
    one_to_one :role                            # See Role.role_id
  end

  class SourceID < AutoCounter
    value_type 
    one_to_one :source                          # See Source.source_id
  end

  class SourceName < String
    value_type :length => 128
    one_to_one :source                          # See Source.source_name
  end

  class UserID < AutoCounter
    value_type 
    one_to_one :user                            # See User.user_id
  end

  class Year < UnsignedInteger
    value_type :length => 32
  end

  class Event
    identified_by :event_id
    has_one :certificate                        # See Certificate.all_event
    has_one :event_date                         # See EventDate.all_event
    one_to_one :event_id, :class => EventID, :mandatory => true  # See EventID.event
    has_one :event_location                     # See EventLocation.all_event
    has_one :event_type                         # See EventType.all_event
    has_one :official                           # See Official.all_event
  end

  class EventDate
    identified_by :min_year, :max_year, :month, :day
    has_one :day                                # See Day.all_event_date
    has_one :max_year, :class => Year           # See Year.all_event_date_as_max_year
    has_one :min_year, :class => Year           # See Year.all_event_date_as_min_year
    has_one :month                              # See Month.all_event_date
  end

  class EventType
    identified_by :event_type_id
    one_to_one :event_type_id, :class => EventTypeID, :mandatory => true  # See EventTypeID.event_type
    one_to_one :event_type_name, :mandatory => true  # See EventTypeName.event_type
  end

  class Person
    identified_by :person_id
    has_one :address                            # See Address.all_person
    has_one :email                              # See Email.all_person
    has_one :family_name, :class => Name        # See Name.all_person_as_family_name
    has_one :gender                             # See Gender.all_person
    has_one :given_name, :class => Name         # See Name.all_person_as_given_name
    has_one :occupation                         # See Occupation.all_person
    one_to_one :person_id, :class => PersonID, :mandatory => true  # See PersonID.person
    has_one :preferred_picture, :class => Picture  # See Picture.all_person_as_preferred_picture
  end

  class Role
    identified_by :role_id
    one_to_one :event_role_name, :mandatory => true  # See EventRoleName.role
    one_to_one :role_id, :class => RoleID, :mandatory => true  # See RoleID.role
  end

  class Source
    identified_by :source_id
    one_to_one :source_id, :class => SourceID, :mandatory => true  # See SourceID.source
    one_to_one :source_name, :mandatory => true  # See SourceName.source
    has_one :user, :mandatory => true           # See User.all_source
  end

  class User
    identified_by :user_id
    has_one :email                              # See Email.all_user
    one_to_one :user_id, :class => UserID, :mandatory => true  # See UserID.user
  end

  class Friendship
    identified_by :user, :other_user
    has_one :other_user, :class => User, :mandatory => true  # See User.all_friendship_as_other_user
    has_one :user, :mandatory => true           # See User.all_friendship
    maybe :is_confirmed
  end

  class Participation
    identified_by :person, :role, :event, :source
    has_one :event, :mandatory => true          # See Event.all_participation
    has_one :person, :mandatory => true         # See Person.all_participation
    has_one :role, :mandatory => true           # See Role.all_participation
    has_one :source, :mandatory => true         # See Source.all_participation
  end

end
