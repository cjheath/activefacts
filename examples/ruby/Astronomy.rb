require 'activefacts/api'

module ::Astronomy

  class AstronomicalObjectCode < String
    value_type :length => 12
  end

  class Mass < Real
    value_type :length => 32
  end

  class MoonName < String
    value_type :length => 256
  end

  class NrDays < Real
    value_type :length => 32
  end

  class PlanetName < String
    value_type :length => 256
  end

  class AstronomicalObject
    identified_by :astronomical_object_code
    one_to_one :astronomical_object_code, :mandatory => true  # See AstronomicalObjectCode.astronomical_object
    has_one :mass                               # See Mass.all_astronomical_object
  end

  class Moon < AstronomicalObject
    identified_by :moon_name
    one_to_one :moon_name, :mandatory => true   # See MoonName.moon
  end

  class Orbit
    identified_by :astronomicalobject
    one_to_one :astronomicalobject, :class => AstronomicalObject, :mandatory => true  # See AstronomicalObject.orbit_as_astronomicalobject
    has_one :astronomical_object, :mandatory => true  # See AstronomicalObject.all_orbit
    has_one :nr_days                            # See NrDays.all_orbit
  end

  class Planet < AstronomicalObject
    identified_by :planet_name
    one_to_one :planet_name, :mandatory => true  # See PlanetName.planet
  end

  class Star < AstronomicalObject
  end

end
