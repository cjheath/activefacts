require 'activefacts/api'

module ::Warehousing

  class BinID < AutoCounter
    value_type 
  end

  class DispatchID < AutoCounter
    value_type 
  end

  class DispatchItemID < AutoCounter
    value_type 
  end

  class PartyID < AutoCounter
    value_type 
  end

  class ProductID < AutoCounter
    value_type 
  end

  class PurchaseOrderID < AutoCounter
    value_type 
  end

  class Quantity < UnsignedInteger
    value_type :length => 32
  end

  class ReceiptID < AutoCounter
    value_type 
  end

  class ReceivedItemID < AutoCounter
    value_type 
  end

  class SalesOrderID < AutoCounter
    value_type 
  end

  class TransferRequestID < AutoCounter
    value_type 
  end

  class WarehouseID < AutoCounter
    value_type 
  end

  class Bin
    identified_by :bin_id
    one_to_one :bin_id, BinID                   # See BinID.bin
    has_one :product                            # See Product.all_bin
    has_one :quantity                           # See Quantity.all_bin
    has_one :warehouse                          # See Warehouse.all_bin
  end

  class Dispatch
    identified_by :dispatch_id
    one_to_one :dispatch_id, DispatchID         # See DispatchID.dispatch
  end

  class DispatchItem
    identified_by :dispatch_item_id
    has_one :dispatch                           # See Dispatch.all_dispatch_item
    one_to_one :dispatch_item_id, DispatchItemID  # See DispatchItemID.dispatch_item
    has_one :product                            # See Product.all_dispatch_item
    has_one :quantity                           # See Quantity.all_dispatch_item
    has_one :sales_order_item                   # See SalesOrderItem.all_dispatch_item
    has_one :transfer_request                   # See TransferRequest.all_dispatch_item
  end

  class Party
    identified_by :party_id
    one_to_one :party_id, PartyID               # See PartyID.party
  end

  class Product
    identified_by :product_id
    one_to_one :product_id, ProductID           # See ProductID.product
  end

  class PurchaseOrder
    identified_by :purchase_order_id
    one_to_one :purchase_order_id, PurchaseOrderID  # See PurchaseOrderID.purchase_order
    has_one :supplier                           # See Supplier.all_purchase_order
    has_one :warehouse                          # See Warehouse.all_purchase_order
  end

  class PurchaseOrderItem
    identified_by :purchase_order, :product
    has_one :product                            # See Product.all_purchase_order_item
    has_one :purchase_order                     # See PurchaseOrder.all_purchase_order_item
    has_one :quantity                           # See Quantity.all_purchase_order_item
  end

  class Receipt
    identified_by :receipt_id
    one_to_one :receipt_id, ReceiptID           # See ReceiptID.receipt
  end

  class ReceivedItem
    identified_by :received_item_id
    has_one :product                            # See Product.all_received_item
    has_one :purchase_order_item                # See PurchaseOrderItem.all_received_item
    has_one :quantity                           # See Quantity.all_received_item
    has_one :receipt                            # See Receipt.all_received_item
    one_to_one :received_item_id, ReceivedItemID  # See ReceivedItemID.received_item
    has_one :transfer_request                   # See TransferRequest.all_received_item
  end

  class SalesOrder
    identified_by :sales_order_id
    has_one :customer                           # See Customer.all_sales_order
    one_to_one :sales_order_id, SalesOrderID    # See SalesOrderID.sales_order
    has_one :warehouse                          # See Warehouse.all_sales_order
  end

  class SalesOrderItem
    identified_by :sales_order, :product
    has_one :product                            # See Product.all_sales_order_item
    has_one :quantity                           # See Quantity.all_sales_order_item
    has_one :sales_order                        # See SalesOrder.all_sales_order_item
  end

  class Supplier < Party
  end

  class TransferRequest
    identified_by :transfer_request_id
    has_one :from_warehouse, "Warehouse"        # See Warehouse.all_transfer_request_as_from_warehouse
    has_one :to_warehouse, "Warehouse"          # See Warehouse.all_transfer_request_as_to_warehouse
    one_to_one :transfer_request_id, TransferRequestID  # See TransferRequestID.transfer_request
  end

  class Warehouse
    identified_by :warehouse_id
    one_to_one :warehouse_id, WarehouseID       # See WarehouseID.warehouse
  end

  class Customer < Party
  end

  class DirectOrderMatch
    identified_by :purchase_order_item, :sales_order_item
    has_one :purchase_order_item                # See PurchaseOrderItem.all_direct_order_match
    has_one :sales_order_item                   # See SalesOrderItem.all_direct_order_match
  end

end
