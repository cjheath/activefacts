require 'activefacts/api'

module OilSupply

  class Month < String
    value_type :length => 3
    has_one :season                             # See Season.all_month
  end

  class Product < String
    value_type :length => 80
  end

  class Quantity < UnsignedInteger
    value_type :length => 32
  end

  class RefineryName < String
    value_type :length => 80
  end

  class Region < String
    value_type :length => 80
  end

  class Season < String
    value_type :length => 6
    # REVISIT: Season has restricted values
  end

  class Transportation < String
    value_type 
  end

  class Year < UnsignedInteger
    value_type :length => 32
  end

  class Refinery
    identified_by :refinery_name
    one_to_one :refinery_name                   # See RefineryName.refinery
  end

  class TransportRoute
    identified_by :transportation, :refinery, :region
    has_one :refinery                           # See Refinery.all_transport_route
    has_one :region                             # See Region.all_transport_route
    has_one :transportation                     # See Transportation.all_transport_route
  end

  class ProductionCommitment
    identified_by :refinery, :month, :product, :quantity
    has_one :month                              # See Month.all_production_commitment
    has_one :product                            # See Product.all_production_commitment
    has_one :quantity                           # See Quantity.all_production_commitment
    has_one :refinery                           # See Refinery.all_production_commitment
  end

  class AcceptableSubstitutes
    identified_by :product, :alternate_product, :season
    has_one :alternate_product, Product         # See Product.all_acceptable_substitutes_by_alternate_product
    has_one :product                            # See Product.all_acceptable_substitutes
    has_one :season                             # See Season.all_acceptable_substitutes
  end

  class RegionalDemand
    identified_by :region, :month, :year, :product
    has_one :month                              # See Month.all_regional_demand
    has_one :product                            # See Product.all_regional_demand
    has_one :quantity                           # See Quantity.all_regional_demand
    has_one :region                             # See Region.all_regional_demand
    has_one :year                               # See Year.all_regional_demand
  end

end
