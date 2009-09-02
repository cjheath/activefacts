require 'activefacts/api'

module ::RedundantDependency

  class AddressId < AutoCounter
    value_type 
  end

  class DistrictNumber < SignedInteger
    value_type :length => 32
  end

  class PoliticianId < AutoCounter
    value_type 
  end

  class PostalCode < SignedInteger
    value_type :length => 32
  end

  class StateOrProvinceId < AutoCounter
    value_type 
  end

  class Address
    identified_by :address_id
    one_to_one :address_id, :mandatory => true  # See AddressId.address
    has_one :legislative_district               # See LegislativeDistrict.all_address
    has_one :postal_code                        # See PostalCode.all_address
    has_one :state_or_province                  # See StateOrProvince.all_address
  end

  class Politician
    identified_by :politician_id
    one_to_one :politician_id, :mandatory => true  # See PoliticianId.politician
  end

  class StateOrProvince
    identified_by :state_or_province_id
    one_to_one :state_or_province_id, :mandatory => true  # See StateOrProvinceId.state_or_province
  end

  class LegislativeDistrict
    identified_by :district_number, :state_or_province
    has_one :district_number, :mandatory => true  # See DistrictNumber.all_legislative_district
    one_to_one :politician, :mandatory => true  # See Politician.legislative_district
    has_one :state_or_province, :mandatory => true  # See StateOrProvince.all_legislative_district
  end

end
