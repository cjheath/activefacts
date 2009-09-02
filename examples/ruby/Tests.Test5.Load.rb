require 'activefacts/api'

module ::ORMModel1

  class AccuracyLevel < SignedInteger
    value_type :length => 32
  end

  class Date < ::Date
    value_type 
  end

  class PartyId < AutoCounter
    value_type 
  end

  class PartyName < String
    value_type 
  end

  class Ymd < ::Date
    value_type 
  end

  class Accuracy
    identified_by :accuracy_level
    one_to_one :accuracy_level, :mandatory => true  # See AccuracyLevel.accuracy
  end

  class EventDate
    identified_by :ymd
    one_to_one :ymd, :mandatory => true         # See ymd.event_date
  end

  class Party
    identified_by :party_id
    one_to_one :party_id, :mandatory => true    # See PartyId.party
  end

  class PartyMoniker
    identified_by :party
    one_to_one :party, :mandatory => true       # See Party.party_moniker
    has_one :party_name, :mandatory => true     # See PartyName.all_party_moniker
    has_one :accuracy, :mandatory => true       # See Accuracy.all_party_moniker
  end

  class Person < Party
  end

  class Birth
    identified_by :person
    has_one :event_date, :mandatory => true     # See EventDate.all_birth
    one_to_one :person, :mandatory => true      # See Person.birth
    has_one :attending_doctor, :class => "Doctor"  # See Doctor.all_birth_as_attending_doctor
  end

  class Death
    identified_by :person
    one_to_one :person, :mandatory => true      # See Person.death
    has_one :death_event_date, :class => EventDate  # See EventDate.all_death_as_death_event_date
  end

  class Doctor < Person
  end

end
