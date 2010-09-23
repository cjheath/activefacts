require 'dm-core'

class SomeString
  include DataMapper::Resource

  property :is_long, Boolean, :required => true	# Some String is long
  property :some_string_value, String, :key => true	# Some String has value
end

