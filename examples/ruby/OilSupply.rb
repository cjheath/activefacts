require 'activefacts/api'

module ::OilSupply

  class Cost < Money
    value_type 
  end

  class MonthNr < SignedInteger
    value_type :length => 32
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
    restrict 'Autumn', 'Spring', 'Summer', 'Winter'
  end

  class TransportMethod < String
    value_type 
    restrict 'Rail', 'Road', 'Sea'
  end

  class YearNr < SignedInteger
    value_type :length => 32
  end

  class Month
    identified_by :month_nr
    one_to_one :month_nr, :mandatory => true    # See MonthNr.month
    has_one :season, :mandatory => true         # See Season.all_month
  end

  class Product
    identified_by :product_name
    one_to_one :product_name, :mandatory => true  # See ProductName.product
  end

  class Refinery
    identified_by :refinery_name
    one_to_one :refinery_name, :mandatory => true  # See RefineryName.refinery
  end

  class Region
    identified_by :region_name
    one_to_one :region_name, :mandatory => true  # See RegionName.region
  end

  class TransportRoute
    identified_by :transport_method, :refinery, :region
    has_one :refinery, :mandatory => true       # See Refinery.all_transport_route
    has_one :region, :mandatory => true         # See Region.all_transport_route
    has_one :transport_method, :mandatory => true  # See TransportMethod.all_transport_route
    has_one :cost                               # See Cost.all_transport_route
  end

  class Year
    identified_by :year_nr
    one_to_one :year_nr, :mandatory => true     # See YearNr.year
  end

  class AcceptableSubstitution
    identified_by :product, :alternate_product, :season
    has_one :alternate_product, :class => Product, :mandatory => true  # See Product.all_acceptable_substitution_as_alternate_product
    has_one :product, :mandatory => true        # See Product.all_acceptable_substitution
    has_one :season, :mandatory => true         # See Season.all_acceptable_substitution
  end

  class SupplyPeriod
    identified_by :year, :month
    has_one :month, :mandatory => true          # See Month.all_supply_period
    has_one :year, :mandatory => true           # See Year.all_supply_period
  end

  class ProductionForecast
    identified_by :refinery, :supply_period, :product
    has_one :product, :mandatory => true        # See Product.all_production_forecast
    has_one :quantity, :mandatory => true       # See Quantity.all_production_forecast
    has_one :refinery, :mandatory => true       # See Refinery.all_production_forecast
    has_one :supply_period, :mandatory => true  # See SupplyPeriod.all_production_forecast
    has_one :cost                               # See Cost.all_production_forecast
  end

  class RegionalDemand
    identified_by :region, :supply_period, :product
    has_one :product, :mandatory => true        # See Product.all_regional_demand
    has_one :quantity, :mandatory => true       # See Quantity.all_regional_demand
    has_one :region, :mandatory => true         # See Region.all_regional_demand
    has_one :supply_period, :mandatory => true  # See SupplyPeriod.all_regional_demand
  end

end
