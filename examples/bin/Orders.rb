require 'examples/ruby/Orders'

include ActiveFacts
include Orders

MAX=3

#puts OrderLine.roles.verbalise

c = ActiveFacts::Constellation.new(Orders)
order = c.Order(c.OrderID(nil))
puts order.verbalise

skus = (1..MAX).to_a.map{|i|
    sku = c.SKU(c.SKUID(nil))
    sku.description = "Description of SKU #{i}"
    sku
  }

(1..MAX).each{|i|
    orderline = c.OrderLine(i, order)
    orderline.sk_u = skus[rand(skus.size)]
    orderline.quantity_number = rand(10)+1
  }

puts c.verbalise
