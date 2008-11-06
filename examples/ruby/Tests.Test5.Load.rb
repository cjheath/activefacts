require 'activefacts/api'

module ORMModel1

  class Accuracy_level < SignedInteger
    value_type :length => 32
  end

  class PartyName < String
    value_type 
  end

  class Party_id < AutoCounter
    value_type 
  end

  class ymd < ::Date
    value_type 
  end

  class Accuracy
    identified_by :accuracy_level
    one_to_one :accuracy_level, Accuracy_level  # See Accuracy_level.accuracy
  end

  class Date
    identified_by :ymd
    one_to_one :ymd, ymd                        # See ymd.date
  end

  class Party
    identified_by :party_id
    one_to_one :party_id, Party_id              # See Party_id.party
    has_one :party_name                         # See PartyName.all_party
  end

  class PartyMoniker
    identified_by :party
    has_one :party                              # See Party.all_party_moniker
    has_one :party_name                         # See PartyName.all_party_moniker
    has_one :accuracy                           # See Accuracy.all_party_moniker
  end

  class Person < Party
    has_one :date                               # See Date.all_person
    maybe :died
  end

  class Birth
    identified_by :person
    has_one :date                               # See Date.all_birth
    has_one :person                             # See Person.all_birth
    has_one :attending_doctor, "Doctor"         # See Doctor.all_birth_by_attending_doctor
  end

  class Death
    identified_by :died
    has_one :died, Person                       # See Person.all_death_by_died
    has_one :death_date, Date                   # See Date.all_death_by_death_date
  end

  class Doctor < Person
  end

end
