require 'activefacts/api'

module ::Moon

  class MoonName < String
    value_type 
  end

  class NrDaysNr < SignedInteger
    value_type :length => 32
  end

  class PlanetName < String
    value_type 
  end

  class Moon
    identified_by :moon_name
    one_to_one :moon_name, :mandatory => true   # See MoonName.moon
  end

  class NrDays
    identified_by :nr_days_nr
    one_to_one :nr_days_nr, :mandatory => true  # See NrDaysNr.nr_days
  end

  class Orbit
    identified_by :moon
    one_to_one :moon, :mandatory => true        # See Moon.orbit
    has_one :nr_days                            # See NrDays.all_orbit
    has_one :planet, :mandatory => true         # See Planet.all_orbit
  end

  class Planet
    identified_by :planet_name
    one_to_one :planet_name, :mandatory => true  # See PlanetName.planet
  end

end
