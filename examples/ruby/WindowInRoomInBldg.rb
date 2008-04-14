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
    has_one :building
    has_one :room_number
  end

  class Window
    identified_by :room, :wall_number, :window_number
    has_one :room
    has_one :wall_number
    has_one :window_number
  end

end
