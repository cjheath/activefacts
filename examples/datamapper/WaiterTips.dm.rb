require 'dm-core'

class Meal
  include DataMapper::Resource

  property :meal_id, Serial, :required => true, :key => true	# Meal has MealId
  has n, :waiter_tip, 'WaiterTip'	# Waiter for serving Meal reported a tip of Amount
  has n, :service	# Waiter served Meal
end

class Service
  include DataMapper::Resource

  property :waiter_nr, Integer, :required => true, :key => true	# Service is where Waiter served Meal and Waiter has WaiterNr
  property :meal_id, Serial, :required => true, :key => true	# Service is where Waiter served Meal and Meal has MealId
  belongs_to :meal	# Meal is involved in Service
  property :amount_audvalue, Decimal, :required => false	# maybe Service earned a tip of Amount and Amount has AUDValue
end

class WaiterTip
  include DataMapper::Resource

  property :waiter_nr, Integer, :required => true, :key => true	# WaiterTip is where Waiter for serving Meal reported a tip of Amount and Waiter has WaiterNr
  property :meal_id, Serial, :required => true, :key => true	# WaiterTip is where Waiter for serving Meal reported a tip of Amount and Meal has MealId
  belongs_to :meal	# Meal is involved in WaiterTip
  property :amount_audvalue, Decimal, :required => true, :key => true	# WaiterTip is where Waiter for serving Meal reported a tip of Amount and Amount has AUDValue
end

