require 'activefacts/api'

module Address

  class City < String
    value_type :length => 64
  end

  class CompanyName < String
    value_type 
  end

  class FamilyName < String
    value_type :length => 20
  end

  class GivenNames < String
    value_type :length => 20
  end

  class Number < String
    value_type :length => 12
  end

  class Postcode < String
    value_type 
  end

  class StreetLine < String
    value_type :length => 64
  end

  class Company
    identified_by :company_name
    has_one :address                            # See Address.all_company
    one_to_one :company_name                    # See CompanyName.company
  end

  class Family
    identified_by :family_name
    one_to_one :family_name                     # See FamilyName.family
  end

  class Person
    identified_by :family, :given_names
    has_one :address                            # See Address.all_person
    has_one :family                             # See Family.all_person
    has_one :given_names                        # See GivenNames.all_person
  end

  class Street
    identified_by :first_street_line, :second_street_line, :third_street_line
    has_one :first_street_line, StreetLine      # See StreetLine.all_street_by_first_street_line
    has_one :second_street_line, StreetLine     # See StreetLine.all_street_by_second_street_line
    has_one :third_street_line, StreetLine      # See StreetLine.all_street_by_third_street_line
  end

  class Address
    identified_by :street_number, :street, :city, :postcode
    has_one :city                               # See City.all_address
    has_one :postcode                           # See Postcode.all_address
    has_one :street                             # See Street.all_address
    has_one :street_number, Number              # See Number.all_address_by_street_number
  end

end
