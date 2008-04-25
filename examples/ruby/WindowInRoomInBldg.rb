require 'activefacts/api'

module WindowInRoomInBldg

  class Building < SignedInteger
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

  class Room
    identified_by :building, :room_number
    has_one :building                           # See Building.all_room
    has_one :room_number                        # See RoomNumber.all_room
  end

  class Window
    identified_by :room, :wall_number, :window_number
    has_one :room                               # See Room.all_window
    has_one :wall_number                        # See WallNumber.all_window
    has_one :window_number                      # See WindowNumber.all_window
  end

end
