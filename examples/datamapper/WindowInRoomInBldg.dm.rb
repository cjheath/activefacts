require 'dm-core'

class Window
  include DataMapper::Resource

  property :wall_number, Integer, :key => true	# Window is located in Wall Number
  property :window_number, Integer, :key => true	# Window has Window Number
  property :room_building, Integer, :key => true	# Window is in Room and Room is in Building
  property :room_number, Integer, :key => true	# Window is in Room and Room has Room Number
end

