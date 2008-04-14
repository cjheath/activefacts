require 'activefacts/api'

module NestedWithCustomPI

  class Correspondence_ID < AutoCounter
    value_type 
  end

  class Number1 < SignedInteger
    value_type :length => 32
  end

  class Text1_Name < String
    value_type 
  end

  class Thing_ID < AutoCounter
    value_type 
  end

  class Text1
    identified_by :text1_name
    one_to_one :text1_name, Text1_Name
  end

  class Correspondence < Thing
    identified_by :correspondence_i_d
    has_one :text1
    has_one :number1
    one_to_one :correspondence_i_d, Correspondence_ID
  end

  class Thing
    identified_by :thing_i_d
    one_to_one :thing_i_d, Thing_ID
  end

  class Thong < Correspondence
    maybe :is_foo
  end

end
