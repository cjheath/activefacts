require 'activefacts/api'

module ::OilSupply

  class Cost < Money
    value_type 
  end

  class MonthCode < FixedLengthText
    value_type 
  end

  class ProductName < String
    value_type 
  end

  class Quantity < UnsignedInteger
    value_type :length => 32
  end

  class RefineryName < String
    value_type :length => 80
  end

  class RegionName < String
    value_type 
  end

  class Season < String
    value_type :length => 6
    # REVISIT: Season has restricted values
  end

  class TransportMethod < String
    value_type 
    # REVISIT: TransportMethod has restricted values
  end

  class YearNr < SignedInteger
    value_type :length => 32
  end

  class Month
    identified_by :month_code
    one_to_one :month_code, :mandatory          # See MonthCode.month
    has_one :season, :mandatory                 # See Season.all_month
  end

  class Product
    identified_by :product_name
    one_to_one :product_name, :mandatory        # See ProductName.product
  end

  class Refinery
    identified_by :refinery_name
    one_to_one :refinery_name, :mandatory       # See RefineryName.refinery
  end

  class Region
    identified_by :region_name
    one_to_one :region_name, :mandatory         # See RegionName.region
  end

  class TransportRoute
    identified_by :transport_method, :refinery, :region
    has_one :refinery                           # See Refinery.all_transport_route
    has_one :region                             # See Region.all_transport_route
    has_one :transport_method                   # See TransportMethod.all_transport_route
    has_one :cost                               # See Cost.all_transport_route
  end

  class Year
    identified_by :year_nr
    one_to_one :year_nr, :mandatory             # See YearNr.year
  end

  class AcceptableSubstitutes
    identified_by :product, :alternate_product, :season
    has_one :alternate_product, Product         # See Product.all_acceptable_substitutes_as_alternate_product
    has_one :product                            # See Product.all_acceptable_substitutes
    has_one :season                             # See Season.all_acceptable_substitutes
  end

  class SupplyPeriod
    identified_by :year, :month
    has_one :month, :mandatory                  # See Month.all_supply_period
    has_one :year, :mandatory                   # See Year.all_supply_period
  end

  class ProductionForecast
    identified_by :refinery, :product, :supply_period
    has_one :product                            # See Product.all_production_forecast
    has_one :refinery                           # See Refinery.all_production_forecast
    has_one :supply_period                      # See SupplyPeriod.all_production_forecast
    has_one :cost                               # See Cost.all_production_forecast
    has_one :quantity, :mandatory               # See Quantity.all_production_forecast
  end

  class RegionalDemand
    identified_by :region, :product, :supply_period
    has_one :product                            # See Product.all_regional_demand
    has_one :region                             # See Region.all_regional_demand
    has_one :supply_period                      # See SupplyPeriod.all_regional_demand
    has_one :quantity                           # See Quantity.all_regional_demand
  end

end
