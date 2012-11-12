require 'activefacts/api'

module ::WindowInRoomInBldg

  class BuildingNumber < SignedInteger
    value_type :length => 32
  end

  class RoomNumber < SignedInteger
    value_type :length => 32
  end

  class WallNumber < SignedInteger
    value_type :length => 32
  end

  class WindowNumber < UnsignedInteger
    value_type :length => 32
  end

  class Building
    identified_by :building_number
    one_to_one :building_number, :mandatory => true  # See BuildingNumber.building
  end

  class Room
    identified_by :building, :room_number
    has_one :building, :mandatory => true       # See Building.all_room
    has_one :room_number, :mandatory => true    # See RoomNumber.all_room
  end

  class Wall
    identified_by :room, :wall_number
    has_one :room, :mandatory => true           # See Room.all_wall
    has_one :wall_number, :mandatory => true    # See WallNumber.all_wall
  end

  class Window
    identified_by :wall, :window_number
    has_one :wall, :mandatory => true           # See Wall.all_window
    has_one :window_number, :mandatory => true  # See WindowNumber.all_window
  end

end
