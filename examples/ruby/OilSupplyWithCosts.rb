require 'activefacts/api'

module OilSupply

  class Cost < Money
    value_type 
  end

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

  class TransportMethod < String
    value_type 
    # REVISIT: TransportMethod has restricted values
  end

  class Year < SignedInteger
    value_type :length => 32
  end

  class Refinery
    identified_by :refinery_name
    one_to_one :refinery_name                   # See RefineryName.refinery
  end

  class TransportRoute
    identified_by :region, :refinery, :transport_method
    has_one :transport_method                   # See TransportMethod.all_transport_route
    has_one :cost                               # See Cost.all_transport_route
    has_one :refinery                           # See Refinery.all_transport_route
    has_one :region                             # See Region.all_transport_route
  end

  class SupplyPeriod
    identified_by :month, :year
    has_one :year                               # See Year.all_supply_period
    has_one :month                              # See Month.all_supply_period
  end

  class ProductionCommitment
    identified_by :product, :quantity, :refinery, :supply_period
    has_one :supply_period                      # See SupplyPeriod.all_production_commitment
    has_one :refinery                           # See Refinery.all_production_commitment
    has_one :quantity                           # See Quantity.all_production_commitment
    has_one :cost                               # See Cost.all_production_commitment
    has_one :product                            # See Product.all_production_commitment
  end

  class RegionalDemand
    identified_by :product, :supply_period, :region
    has_one :region                             # See Region.all_regional_demand
    has_one :quantity                           # See Quantity.all_regional_demand
    has_one :product                            # See Product.all_regional_demand
    has_one :supply_period                      # See SupplyPeriod.all_regional_demand
  end

  class AcceptableSubstitutes
    identified_by :product, :alternate_product, :season
    has_one :alternate_product, Product         # See Product.all_acceptable_substitutes_by_alternate_product
    has_one :product                            # See Product.all_acceptable_substitutes
    has_one :season                             # See Season.all_acceptable_substitutes
  end

end
