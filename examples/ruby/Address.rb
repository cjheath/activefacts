require 'activefacts/api'

module ::Address

  class City < String
    value_type :length => 64
  end

  class CompanyName < String
    value_type 
    one_to_one :company                         # See Company.company_name
  end

  class FamilyName < String
    value_type :length => 20
    one_to_one :family                          # See Family.family_name
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
    one_to_one :company_name, :mandatory => true  # See CompanyName.company
  end

  class Family
    identified_by :family_name
    one_to_one :family_name, :mandatory => true  # See FamilyName.family
  end

  class Person
    identified_by :family, :given_names
    has_one :address                            # See Address.all_person
    has_one :family, :mandatory => true         # See Family.all_person
    has_one :given_names, :mandatory => true    # See GivenNames.all_person
  end

  class Street
    identified_by :first_street_line, :second_street_line, :third_street_line
    has_one :first_street_line, :class => StreetLine, :mandatory => true  # See StreetLine.all_street_as_first_street_line
    has_one :second_street_line, :class => StreetLine  # See StreetLine.all_street_as_second_street_line
    has_one :third_street_line, :class => StreetLine  # See StreetLine.all_street_as_third_street_line
  end

  class Address
    identified_by :street_number, :street, :city, :postcode
    has_one :city, :mandatory => true           # See City.all_address
    has_one :postcode                           # See Postcode.all_address
    has_one :street, :mandatory => true         # See Street.all_address
    has_one :street_number, :class => Number    # See Number.all_address_as_street_number
  end

end
