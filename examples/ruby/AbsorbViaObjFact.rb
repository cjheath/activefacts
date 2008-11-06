require 'activefacts/api'

module AbsorbViaObjFact

  class Game_Code < FixedLengthText
    value_type 
  end

  class Person_Name < String
    value_type 
  end

  class Game
    identified_by :game_code
    one_to_one :game_code, Game_Code            # See Game_Code.game
  end

  class Person
    identified_by :person_name
    one_to_one :person_name, Person_Name        # See Person_Name.person
  end

  class PersonPlaysGame
    identified_by :person, :game
    has_one :game                               # See Game.all_person_plays_game
    has_one :person                             # See Person.all_person_plays_game
  end

end
