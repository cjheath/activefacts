#
# schema.rb auto-generated using ActiveFacts for Warehousing on 2015-06-22
#

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Schema.define(:version => 20150622153354) do
  enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
  create_table "back_order_allocations", :id => false, :force => true do |t|
    t.column "back_order_allocation_id", :primary_key, :null => false
    t.column "purchase_order_item_id", :integer, :null => false
    t.column "sales_order_item_id", :integer, :null => false
    t.column "quantity", :integer, :limit => 32, :null => false
  end

  add_index "back_order_allocations", ["purchase_order_item_id", "sales_order_item_id"], :name => :index_back_order_allocations_on_purchase_order_item_i__1a63f970, :unique => true

  create_table "bins", :id => false, :force => true do |t|
    t.column "bin_id", :primary_key, :null => false
    t.column "product_id", :integer, :null => true
    t.column "warehouse_id", :integer, :null => true
    t.column "quantity", :integer, :limit => 32, :null => false
  end


  create_table "dispatch_items", :id => false, :force => true do |t|
    t.column "dispatch_item_id", :primary_key, :null => false
    t.column "product_id", :integer, :null => false
    t.column "sales_order_item_id", :integer, :null => true
    t.column "transfer_request_id", :integer, :null => true
    t.column "dispatch_id", :integer, :null => true
    t.column "quantity", :integer, :limit => 32, :null => false
  end


  create_table "parties", :id => false, :force => true do |t|
    t.column "party_id", :primary_key, :null => false
  end


  create_table "products", :id => false, :force => true do |t|
    t.column "product_id", :primary_key, :null => false
  end


  create_table "purchase_orders", :id => false, :force => true do |t|
    t.column "purchase_order_id", :primary_key, :null => false
    t.column "supplier_id", :integer, :null => false
    t.column "warehouse_id", :integer, :null => false
  end


  create_table "purchase_order_items", :id => false, :force => true do |t|
    t.column "purchase_order_item_id", :primary_key, :null => false
    t.column "product_id", :integer, :null => false
    t.column "purchase_order_id", :integer, :null => false
    t.column "quantity", :integer, :limit => 32, :null => false
  end

  add_index "purchase_order_items", ["purchase_order_id", "product_id"], :name => :index_purchase_order_items_on_purchase_order_id_product_id, :unique => true

  create_table "received_items", :id => false, :force => true do |t|
    t.column "received_item_id", :primary_key, :null => false
    t.column "product_id", :integer, :null => false
    t.column "purchase_order_item_id", :integer, :null => true
    t.column "transfer_request_id", :integer, :null => true
    t.column "quantity", :integer, :limit => 32, :null => false
    t.column "receipt_id", :integer, :null => true
  end


  create_table "sales_orders", :id => false, :force => true do |t|
    t.column "sales_order_id", :primary_key, :null => false
    t.column "customer_id", :integer, :null => false
    t.column "warehouse_id", :integer, :null => false
  end


  create_table "sales_order_items", :id => false, :force => true do |t|
    t.column "sales_order_item_id", :primary_key, :null => false
    t.column "product_id", :integer, :null => false
    t.column "sales_order_id", :integer, :null => false
    t.column "quantity", :integer, :limit => 32, :null => false
  end

  add_index "sales_order_items", ["sales_order_id", "product_id"], :name => :index_sales_order_items_on_sales_order_id_product_id, :unique => true

  create_table "transfer_requests", :id => false, :force => true do |t|
    t.column "transfer_request_id", :primary_key, :null => false
    t.column "from_warehouse_id", :integer, :null => false
    t.column "product_id", :integer, :null => false
    t.column "to_warehouse_id", :integer, :null => false
    t.column "quantity", :integer, :limit => 32, :null => false
  end


  create_table "warehouses", :id => false, :force => true do |t|
    t.column "warehouse_id", :primary_key, :null => false
  end


  unless ENV["EXCLUDE_FKS"]
    add_foreign_key :back_order_allocations, :purchase_order_items, :column => :purchase_order_item_id, :primary_key => :purchase_order_item_id, :on_delete => :cascade
    add_index :back_order_allocations, [:purchase_order_item_id], :unique => false
    add_foreign_key :back_order_allocations, :sales_order_items, :column => :sales_order_item_id, :primary_key => :sales_order_item_id, :on_delete => :cascade
    add_index :back_order_allocations, [:sales_order_item_id], :unique => false
    add_foreign_key :bins, :products, :column => :product_id, :primary_key => :product_id, :on_delete => :cascade
    add_index :bins, [:product_id], :unique => false
    add_foreign_key :bins, :warehouses, :column => :warehouse_id, :primary_key => :warehouse_id, :on_delete => :cascade
    add_index :bins, [:warehouse_id], :unique => false
    add_foreign_key :dispatch_items, :products, :column => :product_id, :primary_key => :product_id, :on_delete => :cascade
    add_index :dispatch_items, [:product_id], :unique => false
    add_foreign_key :dispatch_items, :sales_order_items, :column => :sales_order_item_id, :primary_key => :sales_order_item_id, :on_delete => :cascade
    add_index :dispatch_items, [:sales_order_item_id], :unique => false
    add_foreign_key :dispatch_items, :transfer_requests, :column => :transfer_request_id, :primary_key => :transfer_request_id, :on_delete => :cascade
    add_index :dispatch_items, [:transfer_request_id], :unique => false
    add_foreign_key :purchase_orders, :parties, :column => :supplier_id, :primary_key => :party_id, :on_delete => :cascade
    add_index :purchase_orders, [:supplier_id], :unique => false
    add_foreign_key :purchase_orders, :warehouses, :column => :warehouse_id, :primary_key => :warehouse_id, :on_delete => :cascade
    add_index :purchase_orders, [:warehouse_id], :unique => false
    add_foreign_key :purchase_order_items, :products, :column => :product_id, :primary_key => :product_id, :on_delete => :cascade
    add_index :purchase_order_items, [:product_id], :unique => false
    add_foreign_key :purchase_order_items, :purchase_orders, :column => :purchase_order_id, :primary_key => :purchase_order_id, :on_delete => :cascade
    add_index :purchase_order_items, [:purchase_order_id], :unique => false
    add_foreign_key :received_items, :products, :column => :product_id, :primary_key => :product_id, :on_delete => :cascade
    add_index :received_items, [:product_id], :unique => false
    add_foreign_key :received_items, :purchase_order_items, :column => :purchase_order_item_id, :primary_key => :purchase_order_item_id, :on_delete => :cascade
    add_index :received_items, [:purchase_order_item_id], :unique => false
    add_foreign_key :received_items, :transfer_requests, :column => :transfer_request_id, :primary_key => :transfer_request_id, :on_delete => :cascade
    add_index :received_items, [:transfer_request_id], :unique => false
    add_foreign_key :sales_orders, :parties, :column => :customer_id, :primary_key => :party_id, :on_delete => :cascade
    add_index :sales_orders, [:customer_id], :unique => false
    add_foreign_key :sales_orders, :warehouses, :column => :warehouse_id, :primary_key => :warehouse_id, :on_delete => :cascade
    add_index :sales_orders, [:warehouse_id], :unique => false
    add_foreign_key :sales_order_items, :products, :column => :product_id, :primary_key => :product_id, :on_delete => :cascade
    add_index :sales_order_items, [:product_id], :unique => false
    add_foreign_key :sales_order_items, :sales_orders, :column => :sales_order_id, :primary_key => :sales_order_id, :on_delete => :cascade
    add_index :sales_order_items, [:sales_order_id], :unique => false
    add_foreign_key :transfer_requests, :products, :column => :product_id, :primary_key => :product_id, :on_delete => :cascade
    add_index :transfer_requests, [:product_id], :unique => false
    add_foreign_key :transfer_requests, :warehouses, :column => :from_warehouse_id, :primary_key => :warehouse_id, :on_delete => :cascade
    add_index :transfer_requests, [:from_warehouse_id], :unique => false
    add_foreign_key :transfer_requests, :warehouses, :column => :to_warehouse_id, :primary_key => :warehouse_id, :on_delete => :cascade
    add_index :transfer_requests, [:to_warehouse_id], :unique => false
  end
end
