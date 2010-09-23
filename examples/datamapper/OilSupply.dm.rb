require 'dm-core'

class AcceptableSubstitutes
  include DataMapper::Resource

  property :product_name, String, :key => true	# Acceptable Substitutes is where Product may be substituted by alternate-Product in Season and Product has Product Name
  property :alternate_product_name, String, :key => true	# Acceptable Substitutes is where Product may be substituted by alternate-Product in Season and Product has Product Name
  property :season, String, :length => 6, :key => true	# Acceptable Substitutes is where Product may be substituted by alternate-Product in Season
end

class Month
  include DataMapper::Resource

  property :month_nr, Integer, :key => true	# Month has Month Nr
  property :season, String, :length => 6, :required => true	# Month is in Season
end

class ProductionForecast
  include DataMapper::Resource

  property :refinery_name, String, :length => 80, :key => true	# Production Forecast is where Refinery forecasts production of Product in Supply Period and Refinery has Refinery Name
  property :product_name, String, :key => true	# Production Forecast is where Refinery forecasts production of Product in Supply Period and Product has Product Name
  property :supply_period_year_nr, Integer, :key => true	# Production Forecast is where Refinery forecasts production of Product in Supply Period and Supply Period is in Year and Year has Year Nr
  property :supply_period_month_nr, Integer, :key => true	# Production Forecast is where Refinery forecasts production of Product in Supply Period and Supply Period is in Month and Month has Month Nr
  property :cost, Decimal	# maybe Production Forecast predicts Cost
  property :quantity, Integer, :required => true	# Production Forecast is for Quantity
end

class RegionalDemand
  include DataMapper::Resource

  property :region_name, String, :key => true	# Regional Demand is where Region will need Product in Supply Period and Region has Region Name
  property :product_name, String, :key => true	# Regional Demand is where Region will need Product in Supply Period and Product has Product Name
  property :supply_period_year_nr, Integer, :key => true	# Regional Demand is where Region will need Product in Supply Period and Supply Period is in Year and Year has Year Nr
  property :supply_period_month_nr, Integer, :key => true	# Regional Demand is where Region will need Product in Supply Period and Supply Period is in Month and Month has Month Nr
  property :quantity, Integer	# maybe Regional Demand is for Quantity
end

class TransportRoute
  include DataMapper::Resource

  property :transport_method, String, :key => true	# Transport Route is where Transport Method transportation is available from Refinery to Region
  property :refinery_name, String, :length => 80, :key => true	# Transport Route is where Transport Method transportation is available from Refinery to Region and Refinery has Refinery Name
  property :region_name, String, :key => true	# Transport Route is where Transport Method transportation is available from Refinery to Region and Region has Region Name
  property :cost, Decimal	# maybe Transport Route incurs Cost per kl
end

