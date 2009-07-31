require 'activefacts/api'

module ::SeparateSubtype

  class ClaimID < AutoCounter
    value_type 
  end

  class DateTime < ::DateTime
    value_type 
  end

  class DriverName < String
    value_type 
  end

  class Claim
    identified_by :claim_id
    one_to_one :claim_id, ClaimID, :mandatory   # See ClaimID.claim
  end

  class Driver
    identified_by :driver_name
    one_to_one :driver_name, :mandatory         # See DriverName.driver
  end

  class Incident
    identified_by :claim
    one_to_one :claim, :mandatory               # See Claim.incident
    has_one :date_time                          # See DateTime.all_incident
  end

  class VehicleIncident < Incident
    has_one :driver                             # See Driver.all_vehicle_incident
  end

end
