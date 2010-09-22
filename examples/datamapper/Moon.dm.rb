require 'dm-core'

class Moon
  include DataMapper::Resource

  property :moon_name, String, :required => true, :key => true	# Moon has Moon Name
  property :orbit_nr_days_nr, Integer, :required => false	# Orbit is where Moon is in orbit and maybe Orbit has a synodic period of Nr Days and Nr Days has Nr Days Nr
  property :orbit_planet_name, String, :required => true	# Orbit is where Moon is in orbit and Orbit is around Planet and Planet has Planet Name
end

