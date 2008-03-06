require 'activefacts/api'

module Orders

  class Description < String
    value_type :length => 120
  end

  class Number < UnsignedInteger
    value_type :length => 32
  end

  class OrderID < AutoCounter
    value_type 
  end

  class SKUID < AutoCounter
    value_type 
  end

  class Order
    identified_by :order_i_d
    one_to_one :order_i_d
  end

  class OrderLine
    identified_by :number, :order
    has_one :order
    has_one :number
    has_one :sk_u, "SKU"
    has_one :quantity_number, Number
  end

  class SKU
    identified_by :skui_d
    one_to_one :skui_d, SKUID
    has_one :description
  end

end
