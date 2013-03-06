require 'dm-core'
require 'dm-constraints'

class Person
  include DataMapper::Resource

  property :person_name, String, :key => true	# Person has Person Name
end

class Adult < Person
end

class Child < Person
end

class Female < Person
end

class Male < Person
end

class Teenager < Person
end

