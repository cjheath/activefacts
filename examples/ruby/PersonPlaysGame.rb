require 'activefacts/api'

module ::PersonPlaysGame

  class GameCode < Char
    value_type 
    one_to_one :game                            # See Game.game_code
  end

  class PersonName < String
    value_type 
    one_to_one :person                          # See Person.person_name
  end

  class Game
    identified_by :game_code
    one_to_one :game_code, :mandatory => true   # See GameCode.game
  end

  class Person
    identified_by :person_name
    one_to_one :person_name, :mandatory => true  # See PersonName.person
  end

  class Playing
    identified_by :person, :game
    has_one :game, :mandatory => true           # See Game.all_playing
    has_one :person, :mandatory => true         # See Person.all_playing
  end

end
