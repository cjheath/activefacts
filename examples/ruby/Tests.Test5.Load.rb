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
    one_to_one :accuracy_level, :mandatory      # See AccuracyLevel.accuracy
  end

  class EventDate
    identified_by :ymd
    one_to_one :ymd, :mandatory                 # See ymd.event_date
  end

  class Party
    identified_by :party_id
    one_to_one :party_id, :mandatory            # See PartyId.party
  end

  class PartyMoniker
    identified_by :party
    one_to_one :party, :mandatory               # See Party.party_moniker
    has_one :party_name, :mandatory             # See PartyName.all_party_moniker
    has_one :accuracy, :mandatory               # See Accuracy.all_party_moniker
  end

  class Person < Party
  end

  class Birth
    identified_by :person
    has_one :event_date, :mandatory             # See EventDate.all_birth
    one_to_one :person, :mandatory              # See Person.birth
    has_one :attending_doctor, "Doctor"         # See Doctor.all_birth_as_attending_doctor
  end

  class Death
    identified_by :person
    one_to_one :person, :mandatory              # See Person.death
    has_one :death_event_date, EventDate        # See EventDate.all_death_as_death_event_date
  end

  class Doctor < Person
  end

end
