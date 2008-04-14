require 'activefacts/api'

module E1

  class Count < UnsignedInteger
    value_type :length => 32
  end

  class Name < String
    value_type 
    has_one :count
  end

end
