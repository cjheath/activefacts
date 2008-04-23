require 'activefacts/api'

module Address

  class Address_Id < AutoCounter
    value_type 
  end

  class City < String
    value_type :length => 64
  end

  class FamilyName < String
    value_type :length => 20
  end

  class GivenNames < String
    value_type :length => 20
  end

  class Postcode < String
    value_type 
  end

  class StreetLine < String
    value_type :length => 64
  end

  class StreetNumber < String
    value_type :length => 12
  end

  class Family
    identified_by :family_name
    one_to_one :family_name
  end

  class Person
    identified_by :family, :given_names
    has_one :family
    has_one :given_names
    has_one :address
  end

  class Street
    identified_by :first_line, :second_line, :third_line
    has_one :first_line, StreetLine
    has_one :second_line, StreetLine
    has_one :third_line, StreetLine
  end

  class Address
    identified_by :street_number, :street, :city, :postcode
    has_one :street
    has_one :city
    has_one :postcode
    has_one :street_number
  end

end
