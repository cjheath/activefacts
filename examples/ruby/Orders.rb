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
    identified_by :order_id
    one_to_one :order_id, OrderID               # See OrderID.order_by_order_id
  end

  class OrderLine
    identified_by :order, :number
    has_one :number                             # See Number.all_order_line
    has_one :order                              # See Order.all_order_line
    has_one :quantity_number, Number            # See Number.all_order_line_by_quantity_number
    has_one :sku, "SKU"                         # See SKU.all_order_line_by_sku
  end

  class SKU
    identified_by :skuid
    has_one :description, :sku                  # See Description.all_sku
    one_to_one :skuid, SKUID, :sku              # See SKUID.sku_by_skuid
  end

end
