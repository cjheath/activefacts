require 'dm-core'
require 'dm-constraints'

class Person
  include DataMapper::Resource

  property :person_id, Serial	# Person has Person ID
  property :name, String, :required => true	# Person is called Name
end

class Boy < Person
  has 1, :girlfriend_as_boyfriend, 'Girl', :child_key => [:boyfriend_id], :parent_key => [:person_id]	# Girl (as Girlfriend) is going out with Boy (as Boyfriend)
end

class Girl < Person
  property :boyfriend_id, Integer	# maybe Girl (as Girlfriend) is going out with Boy (as Boyfriend) and Person has Person ID
  has 1, :boyfriend, 'Boy', :parent_key => [:boyfriend_id], :child_key => [:person_id]	# Girl (as Girlfriend) is going out with Boy (as Boyfriend)
end

