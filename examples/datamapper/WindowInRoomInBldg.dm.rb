require 'dm-core'
require 'dm-constraints'

class Window
  include DataMapper::Resource

  property :wall_room_building_number, Integer, :key => true	# Window is located in Wall and Wall is in Room and Room is in Building and Building has Building Number
  property :wall_room_number, Integer, :key => true	# Window is located in Wall and Wall is in Room and Room has Room Number
  property :wall_number, Integer, :key => true	# Window is located in Wall and Wall has Wall Number
  property :window_number, Integer, :key => true	# Window has Window Number
end

