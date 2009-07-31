require 'activefacts/api'

module ::SubtypePI

  class EntrantID < AutoCounter
    value_type 
  end

  class FamilyName < String
    value_type 
  end

  class GivenName < String
    value_type 
  end

  class TeamID < AutoCounter
    value_type 
  end

  class Entrant
    identified_by :entrant_id
    one_to_one :entrant_id, EntrantID, :mandatory  # See EntrantID.entrant
  end

  class EntrantHasGivenName
    identified_by :entrant, :given_name
    has_one :entrant, :mandatory                # See Entrant.all_entrant_has_given_name
    has_one :given_name                         # See GivenName.all_entrant_has_given_name
  end

  class Team < Entrant
    identified_by :team_id
    one_to_one :team_id, TeamID, :mandatory     # See TeamID.team
  end

  class Competitor < Entrant
    has_one :family_name, :mandatory            # See FamilyName.all_competitor
  end

end
