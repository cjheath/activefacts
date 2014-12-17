require 'activefacts/api'

module ::SeparateSubtype

  class ClaimID < AutoCounter
    value_type 
    one_to_one :claim                           # See Claim.claim_id
  end

  class DateTime < ::DateTime
    value_type 
  end

  class PersonName < String
    value_type 
    one_to_one :person                          # See Person.person_name
  end

  class Claim
    identified_by :claim_id
    one_to_one :claim_id, :class => ClaimID, :mandatory => true  # See ClaimID.claim
  end

  class Incident
    identified_by :claim
    one_to_one :claim, :mandatory => true       # See Claim.incident
    has_one :date_time                          # See DateTime.all_incident
    has_one :witness                            # See Witness.all_incident
  end

  class Person
    identified_by :person_name
    one_to_one :person_name, :mandatory => true  # See PersonName.person
  end

  class VehicleIncident < Incident
    has_one :driver                             # See Driver.all_vehicle_incident
  end

  class Witness < Person
  end

  class Driver < Person
  end

end
