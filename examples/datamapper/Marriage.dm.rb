require 'dm-core'
require 'dm-constraints'

class Marriage
  include DataMapper::Resource

  property :husband_family_name, String, :key => true	# Marriage is by husband-Person and Person has family-Name
  property :husband_given_name, String, :key => true	# Marriage is by husband-Person and Person has given-Name
  belongs_to :husband, 'Person', :child_key => [:husband_family_name, :husband_given_name], :parent_key => [:family_name, :given_name]	# Marriage is by husband-Person
  property :wife_family_name, String, :key => true	# Marriage is of wife-Person and Person has family-Name
  property :wife_given_name, String, :key => true	# Marriage is of wife-Person and Person has given-Name
  belongs_to :wife, 'Person', :child_key => [:wife_family_name, :wife_given_name], :parent_key => [:family_name, :given_name]	# Marriage is of wife-Person
end

class Person
  include DataMapper::Resource

  property :family_name, String, :key => true	# Person has family-Name
  property :given_name, String, :key => true	# Person has given-Name
  has n, :marriage_as_husband, 'Marriage', :child_key => [:husband_family_name, :husband_given_name], :parent_key => [:family_name, :given_name]	# Marriage is by husband-Person
  has n, :marriage_as_wife, 'Marriage', :child_key => [:wife_family_name, :wife_given_name], :parent_key => [:family_name, :given_name]	# Marriage is of wife-Person
end

