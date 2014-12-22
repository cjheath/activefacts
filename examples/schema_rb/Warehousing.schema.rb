#
# schema.rb auto-generated using ActiveFacts for Warehousing on 2014-12-22
#

ActiveRecord::Schema.define(:version => 20141222111648) do
  create_table "back_order_allocations", :id => false, :force => true do |t|
    t.integer	"purchase_order_item_id", :null => false
    t.integer	"sales_order_item_id", :null => false
    t.integer	"quantity", :null => false
  end

  add_index "back_order_allocations", ["purchase_order_item_id", "sales_order_item_id"], :name => :index_back_order_allocations_on_purchase_order_item_i__1a63f970, :unique => true

  create_table "bins", :primary_key => :bin_id, :force => true do |t|
    t.integer	"product_id"
    t.integer	"warehouse_id"
    t.integer	"quantity", :null => false
  end


  create_table "dispatch_items", :primary_key => :dispatch_item_id, :force => true do |t|
    t.integer	"product_id", :null => false
    t.integer	"sales_order_item_id"
    t.integer	"transfer_request_id"
    t.integer	"dispatch_id"
    t.integer	"quantity", :null => false
  end


  create_table "parties", :primary_key => :party_id, :force => true do |t|

  end


  create_table "products", :primary_key => :product_id, :force => true do |t|

  end


  create_table "purchase_orders", :primary_key => :purchase_order_id, :force => true do |t|
    t.integer	"supplier_id", :null => false
    t.integer	"warehouse_id", :null => false
  end


  create_table "purchase_order_items", :primary_key => :purchase_order_item_id, :force => true do |t|
    t.integer	"product_id", :null => false
    t.integer	"purchase_order_id", :null => false
    t.integer	"quantity", :null => false
  end

  add_index "purchase_order_items", ["purchase_order_id", "product_id"], :name => :index_purchase_order_items_on_purchase_order_id_product_id, :unique => true

  create_table "received_items", :primary_key => :received_item_id, :force => true do |t|
    t.integer	"product_id", :null => false
    t.integer	"purchase_order_item_id"
    t.integer	"transfer_request_id"
    t.integer	"quantity", :null => false
    t.integer	"receipt_id"
  end


  create_table "sales_orders", :primary_key => :sales_order_id, :force => true do |t|
    t.integer	"customer_id", :null => false
    t.integer	"warehouse_id", :null => false
  end


  create_table "sales_order_items", :primary_key => :sales_order_item_id, :force => true do |t|
    t.integer	"product_id", :null => false
    t.integer	"sales_order_id", :null => false
    t.integer	"quantity", :null => false
  end

  add_index "sales_order_items", ["sales_order_id", "product_id"], :name => :index_sales_order_items_on_sales_order_id_product_id, :unique => true

  create_table "transfer_requests", :primary_key => :transfer_request_id, :force => true do |t|
    t.integer	"from_warehouse_id", :null => false
    t.integer	"product_id", :null => false
    t.integer	"to_warehouse_id", :null => false
    t.integer	"quantity", :null => false
  end


  create_table "warehouses", :primary_key => :warehouse_id, :force => true do |t|

  end


  unless ENV["EXCLUDE_FKS"]
    add_foreign_key :back_order_allocations, :purchase_order_items, :column => :purchase_order_item_id, :primary_key => :purchase_order_item_id, :dependent => :cascade
    add_foreign_key :back_order_allocations, :sales_order_items, :column => :sales_order_item_id, :primary_key => :sales_order_item_id, :dependent => :cascade
    add_foreign_key :bins, :products, :column => :product_id, :primary_key => :product_id, :dependent => :cascade
    add_foreign_key :bins, :warehouses, :column => :warehouse_id, :primary_key => :warehouse_id, :dependent => :cascade
    add_foreign_key :dispatch_items, :products, :column => :product_id, :primary_key => :product_id, :dependent => :cascade
    add_foreign_key :dispatch_items, :sales_order_items, :column => :sales_order_item_id, :primary_key => :sales_order_item_id, :dependent => :cascade
    add_foreign_key :dispatch_items, :transfer_requests, :column => :transfer_request_id, :primary_key => :transfer_request_id, :dependent => :cascade
    add_foreign_key :purchase_orders, :parties, :column => :supplier_id, :primary_key => :party_id, :dependent => :cascade
    add_foreign_key :purchase_orders, :warehouses, :column => :warehouse_id, :primary_key => :warehouse_id, :dependent => :cascade
    add_foreign_key :purchase_order_items, :products, :column => :product_id, :primary_key => :product_id, :dependent => :cascade
    add_foreign_key :purchase_order_items, :purchase_orders, :column => :purchase_order_id, :primary_key => :purchase_order_id, :dependent => :cascade
    add_foreign_key :received_items, :products, :column => :product_id, :primary_key => :product_id, :dependent => :cascade
    add_foreign_key :received_items, :purchase_order_items, :column => :purchase_order_item_id, :primary_key => :purchase_order_item_id, :dependent => :cascade
    add_foreign_key :received_items, :transfer_requests, :column => :transfer_request_id, :primary_key => :transfer_request_id, :dependent => :cascade
    add_foreign_key :sales_orders, :parties, :column => :customer_id, :primary_key => :party_id, :dependent => :cascade
    add_foreign_key :sales_orders, :warehouses, :column => :warehouse_id, :primary_key => :warehouse_id, :dependent => :cascade
    add_foreign_key :sales_order_items, :products, :column => :product_id, :primary_key => :product_id, :dependent => :cascade
    add_foreign_key :sales_order_items, :sales_orders, :column => :sales_order_id, :primary_key => :sales_order_id, :dependent => :cascade
    add_foreign_key :transfer_requests, :products, :column => :product_id, :primary_key => :product_id, :dependent => :cascade
    add_foreign_key :transfer_requests, :warehouses, :column => :from_warehouse_id, :primary_key => :warehouse_id, :dependent => :cascade
    add_foreign_key :transfer_requests, :warehouses, :column => :to_warehouse_id, :primary_key => :warehouse_id, :dependent => :cascade
  end
end
