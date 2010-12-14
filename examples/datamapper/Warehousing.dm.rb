require 'dm-core'
require 'dm-constraints'

class Bin
  include DataMapper::Resource

  property :bin_id, Serial	# Bin has Bin ID
  property :quantity, Integer, :required => true	# Bin contains Quantity
  property :product_id, Integer	# maybe Product is stocked in Bin and Product has Product ID
  belongs_to :product	# Product is stocked in Bin
  property :warehouse_id, Integer	# maybe Warehouse contains Bin and Warehouse has Warehouse ID
  belongs_to :warehouse	# Warehouse contains Bin
end

class DirectOrderMatch
  include DataMapper::Resource

  property :purchase_order_item_purchase_order_id, Integer, :key => true	# Direct Order Match is where Purchase Order Item matches Sales Order Item and Purchase Order includes Purchase Order Item and Purchase Order has Purchase Order ID
  property :purchase_order_item_product_id, Integer, :key => true	# Direct Order Match is where Purchase Order Item matches Sales Order Item and Purchase Order Item is for Product and Product has Product ID
  belongs_to :purchase_order_item, 'PurchaseOrderItem', :child_key => [:purchase_order_item_product_id, :purchase_order_item_purchase_order_id], :parent_key => [:product_id, :purchase_order_id]	# Purchase_Order_Item is involved in Direct Order Match
  property :sales_order_item_sales_order_id, Integer, :key => true	# Direct Order Match is where Purchase Order Item matches Sales Order Item and Sales Order includes Sales Order Item and Sales Order has Sales Order ID
  property :sales_order_item_product_id, Integer, :key => true	# Direct Order Match is where Purchase Order Item matches Sales Order Item and Sales Order Item is for Product and Product has Product ID
  belongs_to :sales_order_item, 'SalesOrderItem', :child_key => [:sales_order_item_product_id, :sales_order_item_sales_order_id], :parent_key => [:product_id, :sales_order_id]	# Sales_Order_Item is involved in Direct Order Match
end

class DispatchItem
  include DataMapper::Resource

  property :dispatch_item_id, Serial	# Dispatch Item has Dispatch Item ID
  property :dispatch_id, Integer	# maybe Dispatch is of Dispatch Item and Dispatch has Dispatch ID
  property :quantity, Integer, :required => true	# Dispatch Item is in Quantity
  property :product_id, Integer, :required => true	# Dispatch Item is Product and Product has Product ID
  belongs_to :product	# Dispatch Item is Product
  property :sales_order_item_sales_order_id, Integer	# maybe Dispatch Item is for Sales Order Item and Sales Order includes Sales Order Item and Sales Order has Sales Order ID
  property :sales_order_item_product_id, Integer	# maybe Dispatch Item is for Sales Order Item and Sales Order Item is for Product and Product has Product ID
  belongs_to :sales_order_item, 'SalesOrderItem', :child_key => [:sales_order_item_product_id, :sales_order_item_sales_order_id], :parent_key => [:product_id, :sales_order_id]	# Dispatch Item is for Sales Order Item
  property :transfer_request_id, Integer	# maybe Dispatch Item is for Transfer Request and Transfer Request has Transfer Request ID
  belongs_to :transfer_request, 'TransferRequest'	# Dispatch Item is for Transfer Request
end

class Party
  include DataMapper::Resource

  property :party_id, Serial	# Party has Party ID
end

class Customer < Party
  has n, :sales_order, 'SalesOrder', :child_key => [:customer_id], :parent_key => [:party_id]	# Customer made Sales Order
end

class Product
  include DataMapper::Resource

  property :product_id, Serial	# Product has Product ID
  has n, :bin	# Product is stocked in Bin
  has n, :dispatch_item, 'DispatchItem'	# Dispatch Item is Product
  has n, :purchase_order_item, 'PurchaseOrderItem'	# Purchase Order Item is for Product
  has n, :received_item, 'ReceivedItem'	# Received Item is Product
  has n, :sales_order_item, 'SalesOrderItem'	# Sales Order Item is for Product
  has n, :transfer_request, 'TransferRequest'	# Transfer Request is for Product
end

class PurchaseOrder
  include DataMapper::Resource

  property :purchase_order_id, Serial	# Purchase Order has Purchase Order ID
  property :supplier_id, Integer, :required => true	# Purchase Order is to Supplier and Party has Party ID
  belongs_to :supplier, :child_key => [:supplier_id], :parent_key => [:party_id]	# Purchase Order is to Supplier
  property :warehouse_id, Integer, :required => true	# Purchase Order is to Warehouse and Warehouse has Warehouse ID
  belongs_to :warehouse	# Purchase Order is to Warehouse
  has n, :purchase_order_item, 'PurchaseOrderItem'	# Purchase Order includes Purchase Order Item
end

class PurchaseOrderItem
  include DataMapper::Resource

  property :product_id, Integer, :key => true	# Purchase Order Item is for Product and Product has Product ID
  belongs_to :product	# Purchase Order Item is for Product
  property :purchase_order_id, Integer, :key => true	# Purchase Order includes Purchase Order Item and Purchase Order has Purchase Order ID
  belongs_to :purchase_order, 'PurchaseOrder'	# Purchase Order includes Purchase Order Item
  property :quantity, Integer, :required => true	# Purchase Order Item is in Quantity
  has n, :received_item, 'ReceivedItem', :child_key => [:purchase_order_item_product_id, :purchase_order_item_purchase_order_id], :parent_key => [:product_id, :purchase_order_id]	# Received Item is for Purchase Order Item
  has n, :direct_order_match, 'DirectOrderMatch', :child_key => [:purchase_order_item_product_id, :purchase_order_item_purchase_order_id], :parent_key => [:product_id, :purchase_order_id]	# Purchase Order Item matches Sales Order Item
end

class ReceivedItem
  include DataMapper::Resource

  property :received_item_id, Serial	# Received Item has Received Item ID
  property :receipt_id, Integer	# maybe Receipt is of Received Item and Receipt has Receipt ID
  property :product_id, Integer, :required => true	# Received Item is Product and Product has Product ID
  belongs_to :product	# Received Item is Product
  property :purchase_order_item_purchase_order_id, Integer	# maybe Received Item is for Purchase Order Item and Purchase Order includes Purchase Order Item and Purchase Order has Purchase Order ID
  property :purchase_order_item_product_id, Integer	# maybe Received Item is for Purchase Order Item and Purchase Order Item is for Product and Product has Product ID
  belongs_to :purchase_order_item, 'PurchaseOrderItem', :child_key => [:purchase_order_item_product_id, :purchase_order_item_purchase_order_id], :parent_key => [:product_id, :purchase_order_id]	# Received Item is for Purchase Order Item
  property :quantity, Integer, :required => true	# Received Item is in Quantity
  property :transfer_request_id, Integer	# maybe Received Item is for Transfer Request and Transfer Request has Transfer Request ID
  belongs_to :transfer_request, 'TransferRequest'	# Received Item is for Transfer Request
end

class SalesOrder
  include DataMapper::Resource

  property :sales_order_id, Serial	# Sales Order has Sales Order ID
  property :warehouse_id, Integer, :required => true	# Sales Order is from Warehouse and Warehouse has Warehouse ID
  belongs_to :warehouse	# Sales Order is from Warehouse
  property :customer_id, Integer, :required => true	# Customer made Sales Order and Party has Party ID
  belongs_to :customer, :child_key => [:customer_id], :parent_key => [:party_id]	# Customer made Sales Order
  has n, :sales_order_item, 'SalesOrderItem'	# Sales Order includes Sales Order Item
end

class SalesOrderItem
  include DataMapper::Resource

  property :product_id, Integer, :key => true	# Sales Order Item is for Product and Product has Product ID
  belongs_to :product	# Sales Order Item is for Product
  property :sales_order_id, Integer, :key => true	# Sales Order includes Sales Order Item and Sales Order has Sales Order ID
  belongs_to :sales_order, 'SalesOrder'	# Sales Order includes Sales Order Item
  property :quantity, Integer, :required => true	# Sales Order Item is in Quantity
  has n, :dispatch_item, 'DispatchItem', :child_key => [:sales_order_item_product_id, :sales_order_item_sales_order_id], :parent_key => [:product_id, :sales_order_id]	# Dispatch Item is for Sales Order Item
  has n, :direct_order_match, 'DirectOrderMatch', :child_key => [:sales_order_item_product_id, :sales_order_item_sales_order_id], :parent_key => [:product_id, :sales_order_id]	# Purchase Order Item matches Sales Order Item
end

class Supplier < Party
  has n, :purchase_order, 'PurchaseOrder', :child_key => [:supplier_id], :parent_key => [:party_id]	# Purchase Order is to Supplier
end

class TransferRequest
  include DataMapper::Resource

  property :transfer_request_id, Serial	# Transfer Request has Transfer Request ID
  property :product_id, Integer, :required => true	# Transfer Request is for Product and Product has Product ID
  belongs_to :product	# Transfer Request is for Product
  property :quantity, Integer, :required => true	# Transfer Request is for Quantity
  property :from_warehouse_id, Integer, :required => true	# Transfer Request is from Warehouse and Warehouse has Warehouse ID
  belongs_to :from_warehouse, 'Warehouse', :child_key => [:from_warehouse_id], :parent_key => [:warehouse_id]	# Transfer Request is from Warehouse
  property :to_warehouse_id, Integer, :required => true	# Transfer Request is to Warehouse and Warehouse has Warehouse ID
  belongs_to :to_warehouse, 'Warehouse', :child_key => [:to_warehouse_id], :parent_key => [:warehouse_id]	# Transfer Request is to Warehouse
  has n, :dispatch_item, 'DispatchItem'	# Dispatch Item is for Transfer Request
  has n, :received_item, 'ReceivedItem'	# Received Item is for Transfer Request
end

class Warehouse
  include DataMapper::Resource

  property :warehouse_id, Serial	# Warehouse has Warehouse ID
  has n, :bin	# Warehouse contains Bin
  has n, :purchase_order, 'PurchaseOrder'	# Purchase Order is to Warehouse
  has n, :sales_order, 'SalesOrder'	# Sales Order is from Warehouse
  has n, :transfer_request_as_from_warehouse, 'TransferRequest', :child_key => [:from_warehouse_id], :parent_key => [:warehouse_id]	# Transfer Request is from Warehouse
  has n, :transfer_request_as_to_warehouse, 'TransferRequest', :child_key => [:to_warehouse_id], :parent_key => [:warehouse_id]	# Transfer Request is to Warehouse
end

