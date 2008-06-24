require 'activefacts/api'

module Warehousing

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
    identified_by :bin_i_d
    one_to_one :bin_i_d                         # See BinID.bin
    has_one :stocked_product                    # See StockedProduct.all_bin
  end

  class Dispatch
    identified_by :dispatch_i_d
    one_to_one :dispatch_i_d                    # See DispatchID.dispatch
  end

  class DispatchItem
    identified_by :dispatch_item_i_d
    has_one :product                            # See Product.all_dispatch_item
    has_one :transfer_request                   # See TransferRequest.all_dispatch_item
    has_one :sales_order_item                   # See SalesOrderItem.all_dispatch_item
    one_to_one :dispatch_item_i_d               # See DispatchItemID.dispatch_item
    has_one :dispatch                           # See Dispatch.all_dispatch_item
  end

  class Party
    identified_by :party_i_d
    one_to_one :party_i_d                       # See PartyID.party
  end

  class Product
    identified_by :product_i_d
    one_to_one :product_i_d                     # See ProductID.product
  end

  class PurchaseOrder
    identified_by :purchase_order_i_d
    has_one :supplier                           # See Supplier.all_purchase_order
    one_to_one :purchase_order_i_d              # See PurchaseOrderID.purchase_order
    has_one :warehouse                          # See Warehouse.all_purchase_order
  end

  class PurchaseOrderItem
    identified_by :purchase_order, :product
    has_one :product                            # See Product.all_purchase_order_item
    has_one :purchase_order                     # See PurchaseOrder.all_purchase_order_item
  end

  class Receipt
    identified_by :receipt_i_d
    one_to_one :receipt_i_d                     # See ReceiptID.receipt
  end

  class ReceivedItem
    identified_by :received_item_i_d
    has_one :purchase_order_item                # See PurchaseOrderItem.all_received_item
    has_one :transfer_request                   # See TransferRequest.all_received_item
    has_one :product                            # See Product.all_received_item
    one_to_one :received_item_i_d               # See ReceivedItemID.received_item
    has_one :receipt                            # See Receipt.all_received_item
  end

  class SalesOrder
    identified_by :sales_order_i_d
    one_to_one :sales_order_i_d                 # See SalesOrderID.sales_order
    has_one :customer                           # See Customer.all_sales_order
  end

  class SalesOrderItem
    identified_by :sales_order, :product
    has_one :product                            # See Product.all_sales_order_item
    has_one :sales_order                        # See SalesOrder.all_sales_order_item
  end

  class DirectOrderMatch
    identified_by :sales_order_item, :purchase_order_item
    has_one :purchase_order_item                # See PurchaseOrderItem.all_direct_order_match
    has_one :sales_order_item                   # See SalesOrderItem.all_direct_order_match
  end

  class Supplier < Party
  end

  class TransferRequest
    identified_by :transfer_request_i_d
    one_to_one :transfer_request_i_d            # See TransferRequestID.transfer_request
    has_one :warehouse                          # See Warehouse.all_transfer_request
    has_one :warehouse                          # See Warehouse.all_transfer_request
  end

  class Warehouse
    identified_by :warehouse_i_d
    one_to_one :warehouse_i_d                   # See WarehouseID.warehouse
    has_one :sales_order                        # See SalesOrder.all_warehouse
    has_one :bin                                # See Bin.all_warehouse
  end

  class StockedProduct
    identified_by :product, :warehouse
    has_one :warehouse                          # See Warehouse.all_stocked_product
    has_one :product                            # See Product.all_stocked_product
  end

  class Customer < Party
  end

end
