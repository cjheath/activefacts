require 'activefacts/api'

module ::Astronomy

  class AstronomicalObjectCode < String
    value_type :length => 12
    one_to_one :astronomical_object             # See AstronomicalObject.astronomical_object_code
  end

  class Mass < Real
    value_type :length => 32
  end

  class MoonName < String
    value_type :length => 256
    one_to_one :moon                            # See Moon.moon_name
  end

  class NrDays < Real
    value_type :length => 32
  end

  class PlanetName < String
    value_type :length => 256
    one_to_one :planet                          # See Planet.planet_name
  end

  class AstronomicalObject
    identified_by :astronomical_object_code
    one_to_one :astronomical_object_code, :mandatory => true  # See AstronomicalObjectCode.astronomical_object
    maybe :is_in_orbit
    has_one :mass                               # See Mass.all_astronomical_object
  end

  class Moon < AstronomicalObject
    identified_by :moon_name
    one_to_one :moon_name, :mandatory => true   # See MoonName.moon
  end

  class Orbit
    identified_by :astronomical_object
    one_to_one :astronomical_object, :mandatory => true  # See AstronomicalObject.orbit
    has_one :center, :class => AstronomicalObject, :mandatory => true  # See AstronomicalObject.all_orbit_as_center
    has_one :nr_days                            # See NrDays.all_orbit
  end

  class Planet < AstronomicalObject
    identified_by :planet_name
    one_to_one :planet_name, :mandatory => true  # See PlanetName.planet
  end

  class Star < AstronomicalObject
  end

end
