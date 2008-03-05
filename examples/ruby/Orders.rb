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
    one_to_one :order_i_d, OrderID, :order
  end

  class OrderLine
    identified_by :number, :order
    has_one :order, Order
    has_one :number, Number
    has_one :sk_u, "SKU", :order_line
    has_one :quantity_number, Number, :order_line
  end

  class SKU
    identified_by :skui_d
    one_to_one :skui_d, SKUID, :sk_u
    has_one :description, Description, :sk_u
  end

end
