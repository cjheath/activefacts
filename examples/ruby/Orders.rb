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
    one_to_one :order_i_d                       # See OrderID.order
  end

  class OrderLine
    identified_by :number, :order
    has_one :order                              # See Order.all_order_line
    has_one :number                             # See Number.all_order_line
    has_one :sk_u, "SKU"                        # See SKU.all_order_line
    has_one :quantity_number, Number            # See Number.all_order_line_by_quantity_number
  end

  class SKU
    identified_by :skui_d
    one_to_one :skui_d, SKUID                   # See SKUID.sk_u
    has_one :description                        # See Description.all_sk_u
  end

end
