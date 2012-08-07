require 'dm-core'
require 'dm-constraints'

class Window
  include DataMapper::Resource

  property :room_building, Integer, :key => true	# Window is in Room and Room is in Building
  property :room_number, Integer, :key => true	# Window is in Room and Room has Room Number
  property :wall_number, Integer, :key => true	# Window is located in Wall Number
  property :window_number, Integer, :key => true	# Window has Window Number
end

