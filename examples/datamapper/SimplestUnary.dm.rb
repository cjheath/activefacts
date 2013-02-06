require 'dm-core'
require 'dm-constraints'

class SomeString
  include DataMapper::Resource

  property :some_string_value, String, :key => true	# Some String has value
  property :is_long, Boolean	# Some String is long
end

