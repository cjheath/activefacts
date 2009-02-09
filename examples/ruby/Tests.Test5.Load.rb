require 'activefacts/api'

module ORMModel1

  class Accuracylevel < SignedInteger
    value_type :length => 32
  end

  class PartyName < String
    value_type 
  end

  class Partyid < AutoCounter
    value_type 
  end

  class ymd < ::Date
    value_type 
  end

  class Accuracy
    identified_by :accuracylevel
    one_to_one :accuracylevel                   # See Accuracylevel.accuracy
  end

  class Date
    identified_by :ymd
    one_to_one :ymd, ymd                        # See ymd.date
  end

  class Party
    identified_by :partyid
    one_to_one :partyid                         # See Partyid.party
  end

  class PartyMoniker
    identified_by :party
    one_to_one :party                           # See Party.party_moniker
    has_one :party_name                         # See PartyName.all_party_moniker
    has_one :accuracy                           # See Accuracy.all_party_moniker
  end

  class Person < Party
    maybe :died
  end

  class Birth
    identified_by :person
    has_one :date                               # See Date.all_birth
    one_to_one :person                          # See Person.birth
    has_one :attending_doctor, "Doctor"         # See Doctor.all_birth_as_attending_doctor
  end

  class Death
    identified_by :person
    one_to_one :person                          # See Person.death
    has_one :death_date, Date                   # See Date.all_death_as_death_date
  end

  class Doctor < Person
  end

end
