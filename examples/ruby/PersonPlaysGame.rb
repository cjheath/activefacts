require 'activefacts/api'

module ::PersonPlaysGame

  class GameCode < FixedLengthText
    value_type 
  end

  class PersonName < String
    value_type 
  end

  class Game
    identified_by :game_code
    one_to_one :game_code, :mandatory           # See GameCode.game
  end

  class Person
    identified_by :person_name
    one_to_one :person_name, :mandatory         # See PersonName.person
  end

  class Playing
    identified_by :person, :game
    has_one :game                               # See Game.all_playing
    has_one :person                             # See Person.all_playing
  end

end
