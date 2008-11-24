require 'activefacts/api'

module AbsorbViaObjFact

  class GameCode < FixedLengthText
    value_type 
  end

  class PersonName < String
    value_type 
  end

  class Game
    identified_by :game_code
    one_to_one :game_code                       # See GameCode.game
  end

  class Person
    identified_by :person_name
    one_to_one :person_name                     # See PersonName.person
  end

  class Playing
    identified_by :person, :game
    has_one :game                               # See Game.all_playing
    has_one :person                             # See Person.all_playing
  end

end
