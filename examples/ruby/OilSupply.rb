require 'activefacts/api'

module OilSupply

  class Month < String
    value_type :length => 3
    has_one :season
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
    one_to_one :refinery_name
  end

  class TransportRoute
    identified_by :region, :refinery, :transportation
    has_one :transportation
    has_one :refinery
    has_one :region
  end

  class ProductionCommitment
    identified_by :product, :quantity, :refinery, :month
    has_one :month
    has_one :refinery
    has_one :quantity
    has_one :product
  end

  class RegionalDemand
    identified_by :product, :year, :month, :region
    has_one :region
    has_one :quantity
    has_one :product
    has_one :month
    has_one :year
  end

  class AcceptableSubstitutes
    identified_by :product, :alternate_product, :season
    has_one :alternate_product, Product
    has_one :product
    has_one :season
  end

end
