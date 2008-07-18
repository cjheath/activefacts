require 'activefacts/api'

module SubtypePI

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
    identified_by :entrant_i_d
    one_to_one :entrant_i_d                     # See EntrantID.entrant
  end

  class EntrantHasGivenName
    identified_by :entrant, :given_name
    has_one :entrant                            # See Entrant.all_entrant_has_given_name
    has_one :given_name                         # See GivenName.all_entrant_has_given_name
  end

  class Team < Entrant
    identified_by :team_i_d
    one_to_one :team_i_d                        # See TeamID.team
  end

  class Competitor < Entrant
    has_one :family_name                        # See FamilyName.all_competitor
  end

end
