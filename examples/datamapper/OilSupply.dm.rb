require 'dm-core'
require 'dm-constraints'

class AcceptableSubstitution
  include DataMapper::Resource

  property :product_name, String, :key => true	# Acceptable Substitution is where Product may be substituted by alternate-Product in Season and Product has Product Name
  belongs_to :product	# Product is involved in Acceptable Substitution
  property :alternate_product_name, String, :key => true	# Acceptable Substitution is where Product may be substituted by alternate-Product in Season and Product has Product Name
  belongs_to :alternate_product, 'Product', :child_key => [:alternate_product_name], :parent_key => [:product_name]	# alternate_Product is involved in Acceptable Substitution
  property :season, String, :length => 6, :key => true	# Acceptable Substitution is where Product may be substituted by alternate-Product in Season
end

class Month
  include DataMapper::Resource

  property :month_nr, Integer, :key => true	# Month has Month Nr
  property :season, String, :length => 6, :required => true	# Month is in Season
end

class Product
  include DataMapper::Resource

  property :product_name, String, :key => true	# Product has Product Name
  has n, :acceptable_substitution, 'AcceptableSubstitution'	# Product may be substituted by alternate-Product in Season
  has n, :acceptable_substitution_as_alternate_product, 'AcceptableSubstitution', :child_key => [:alternate_product_name], :parent_key => [:product_name]	# Product may be substituted by alternate-Product in Season
  has n, :production_forecast, 'ProductionForecast'	# Refinery will make Quantity of Product in Supply Period
  has n, :regional_demand, 'RegionalDemand'	# Region will need Quantity of Product in Supply Period
end

class ProductionForecast
  include DataMapper::Resource

  property :product_name, String, :key => true	# Production Forecast is where Refinery will make Quantity of Product in Supply Period and Product has Product Name
  belongs_to :product	# Product is involved in Production Forecast
  property :refinery_name, String, :length => 80, :key => true	# Production Forecast is where Refinery will make Quantity of Product in Supply Period and Refinery has Refinery Name
  belongs_to :refinery	# Refinery is involved in Production Forecast
  property :cost, Decimal	# maybe Production Forecast predicts Cost
  property :quantity, Integer, :key => true	# Production Forecast is where Refinery will make Quantity of Product in Supply Period
  property :supply_period_month_nr, Integer, :key => true	# Production Forecast is where Refinery will make Quantity of Product in Supply Period and Supply Period is in Month and Month has Month Nr
  property :supply_period_year_nr, Integer, :key => true	# Production Forecast is where Refinery will make Quantity of Product in Supply Period and Supply Period is in Year and Year has Year Nr
end

class Refinery
  include DataMapper::Resource

  property :refinery_name, String, :length => 80, :key => true	# Refinery has Refinery Name
  has n, :production_forecast, 'ProductionForecast'	# Refinery will make Quantity of Product in Supply Period
  has n, :transport_route, 'TransportRoute'	# Transport Method transportation is available from Refinery to Region
end

class Region
  include DataMapper::Resource

  property :region_name, String, :key => true	# Region has Region Name
  has n, :regional_demand, 'RegionalDemand'	# Region will need Quantity of Product in Supply Period
  has n, :transport_route, 'TransportRoute'	# Transport Method transportation is available from Refinery to Region
end

class RegionalDemand
  include DataMapper::Resource

  property :product_name, String, :key => true	# Regional Demand is where Region will need Quantity of Product in Supply Period and Product has Product Name
  belongs_to :product	# Product is involved in Regional Demand
  property :region_name, String, :key => true	# Regional Demand is where Region will need Quantity of Product in Supply Period and Region has Region Name
  belongs_to :region	# Region is involved in Regional Demand
  property :quantity, Integer, :key => true	# Regional Demand is where Region will need Quantity of Product in Supply Period
  property :supply_period_month_nr, Integer, :key => true	# Regional Demand is where Region will need Quantity of Product in Supply Period and Supply Period is in Month and Month has Month Nr
  property :supply_period_year_nr, Integer, :key => true	# Regional Demand is where Region will need Quantity of Product in Supply Period and Supply Period is in Year and Year has Year Nr
end

class TransportRoute
  include DataMapper::Resource

  property :refinery_name, String, :length => 80, :key => true	# Transport Route is where Transport Method transportation is available from Refinery to Region and Refinery has Refinery Name
  belongs_to :refinery	# Refinery is involved in Transport Route
  property :region_name, String, :key => true	# Transport Route is where Transport Method transportation is available from Refinery to Region and Region has Region Name
  belongs_to :region	# Region is involved in Transport Route
  property :cost, Decimal	# maybe Transport Route incurs Cost per kl
  property :transport_method, String, :key => true	# Transport Route is where Transport Method transportation is available from Refinery to Region
end

