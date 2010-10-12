require 'dm-core'
require 'dm-constraints'

class Company
  include DataMapper::Resource

  property :company_name, String, :key => true	# Company has Company Name
  property :address_street_number, String, :length => 12	# maybe Company has head office at Address and maybe Address is at street-Number
  property :address_street_first_street_line, String, :length => 64	# maybe Company has head office at Address and Address is at Street and Street includes first-Street Line
  property :address_street_second_street_line, String, :length => 64	# maybe Company has head office at Address and Address is at Street and maybe Street includes second-Street Line
  property :address_street_third_street_line, String, :length => 64	# maybe Company has head office at Address and Address is at Street and maybe Street includes third-Street Line
  property :address_city, String, :length => 64	# maybe Company has head office at Address and Address is in City
  property :address_postcode, String	# maybe Company has head office at Address and maybe Address is in Postcode
end

class Person
  include DataMapper::Resource

  property :given_names, String, :length => 20, :key => true	# Person has Given Names
  property :family_name, String, :length => 20, :key => true	# Person is of Family and Family has Family Name
  property :address_street_number, String, :length => 12	# maybe Person lives at Address and maybe Address is at street-Number
  property :address_street_first_street_line, String, :length => 64	# maybe Person lives at Address and Address is at Street and Street includes first-Street Line
  property :address_street_second_street_line, String, :length => 64	# maybe Person lives at Address and Address is at Street and maybe Street includes second-Street Line
  property :address_street_third_street_line, String, :length => 64	# maybe Person lives at Address and Address is at Street and maybe Street includes third-Street Line
  property :address_city, String, :length => 64	# maybe Person lives at Address and Address is in City
  property :address_postcode, String	# maybe Person lives at Address and maybe Address is in Postcode
end

