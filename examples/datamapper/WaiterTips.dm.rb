require 'dm-core'
require 'dm-constraints'

class Meal
  include DataMapper::Resource

  property :meal_id, Serial	# Meal has MealId
  has n, :service	# Waiter served Meal
  has n, :waiter_tip, 'WaiterTip'	# Waiter for serving Meal reported a tip of Amount
end

class Service
  include DataMapper::Resource

  property :meal_id, Integer, :key => true	# Service is where Waiter served Meal and Meal has MealId
  belongs_to :meal	# Meal is involved in Service
  property :amount_audvalue, Decimal	# maybe Service earned a tip of Amount and Amount has AUDValue
  property :waiter_nr, Integer, :key => true	# Service is where Waiter served Meal and Waiter has WaiterNr
end

class WaiterTip
  include DataMapper::Resource

  property :meal_id, Integer, :key => true	# WaiterTip is where Waiter for serving Meal reported a tip of Amount and Meal has MealId
  belongs_to :meal	# Meal is involved in WaiterTip
  property :amount_audvalue, Decimal, :key => true	# WaiterTip is where Waiter for serving Meal reported a tip of Amount and Amount has AUDValue
  property :waiter_nr, Integer, :key => true	# WaiterTip is where Waiter for serving Meal reported a tip of Amount and Waiter has WaiterNr
end

