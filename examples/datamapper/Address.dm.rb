require 'dm-core'

class Company
  include DataMapper::Resource

  property :company_name, String, :required => true, :key => true	# Company has Company Name
  property :address_street_number, String, :length => 12, :required => false	# maybe Company has head office at Address and maybe Address is at street-Number
  property :address_street_first_street_line, String, :length => 64, :required => false	# maybe Company has head office at Address and Address is at Street and Street includes first-Street Line
  property :address_street_second_street_line, String, :length => 64, :required => false	# maybe Company has head office at Address and Address is at Street and maybe Street includes second-Street Line
  property :address_street_third_street_line, String, :length => 64, :required => false	# maybe Company has head office at Address and Address is at Street and maybe Street includes third-Street Line
  property :address_city, String, :length => 64, :required => false	# maybe Company has head office at Address and Address is in City
  property :address_postcode, String, :required => false	# maybe Company has head office at Address and maybe Address is in Postcode
end

class Person
  include DataMapper::Resource

  property :given_names, String, :length => 20, :required => true, :key => true	# Person has Given Names
  property :family_name, String, :length => 20, :required => true, :key => true	# Person is of Family and Family has Family Name
  property :address_street_number, String, :length => 12, :required => false	# maybe Person lives at Address and maybe Address is at street-Number
  property :address_street_first_street_line, String, :length => 64, :required => false	# maybe Person lives at Address and Address is at Street and Street includes first-Street Line
  property :address_street_second_street_line, String, :length => 64, :required => false	# maybe Person lives at Address and Address is at Street and maybe Street includes second-Street Line
  property :address_street_third_street_line, String, :length => 64, :required => false	# maybe Person lives at Address and Address is at Street and maybe Street includes third-Street Line
  property :address_city, String, :length => 64, :required => false	# maybe Person lives at Address and Address is in City
  property :address_postcode, String, :required => false	# maybe Person lives at Address and maybe Address is in Postcode
end

