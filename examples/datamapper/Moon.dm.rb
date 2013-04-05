require 'dm-core'
require 'dm-constraints'

class Moon
  include DataMapper::Resource

  property :moon_name, String, :key => true	# Moon has Moon Name
  property :is_in_orbit, Boolean	# Orbit is where Moon is in orbit
  property :orbit_nr_days_nr, Integer	# Orbit is where Moon is in orbit and maybe Orbit has a synodic period of Nr Days and Nr Days has Nr Days Nr
  property :orbit_planet_name, String, :required => true	# Orbit is where Moon is in orbit and Orbit is around Planet and Planet has Planet Name
end

