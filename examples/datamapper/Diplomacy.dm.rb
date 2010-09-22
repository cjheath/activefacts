require 'dm-core'

class Diplomat
  include DataMapper::Resource

  property :diplomat_name, String, :required => true, :key => true	# Diplomat has DiplomatName
  property :represented_country_name, String, :required => true	# Diplomat represents Country (as Represented Country) and Country has CountryName
  property :served_country_name, String, :required => true	# Diplomat serves in Country (as Served Country) and Country has CountryName
  has n, :fluency	# Diplomat speaks Language
end

class Ambassador < Diplomat
  has n, :representation, :child_key => [:ambassador_name], :parent_key => [:diplomat_name]	# Ambassador is from Country (as Represented Country) to Country
end

class Fluency
  include DataMapper::Resource

  property :diplomat_name, String, :required => true, :key => true	# Fluency is where Diplomat speaks Language and Diplomat has DiplomatName
  belongs_to :diplomat	# Diplomat is involved in Fluency
  property :language_name, String, :required => true, :key => true	# Fluency is where Diplomat speaks Language and Language has LanguageName
end

class LanguageUse
  include DataMapper::Resource

  property :language_name, String, :required => true, :key => true	# LanguageUse is where Language is spoken in Country and Language has LanguageName
  property :country_name, String, :required => true, :key => true	# LanguageUse is where Language is spoken in Country and Country has CountryName
end

class Representation
  include DataMapper::Resource

  property :ambassador_name, String, :required => true, :key => true	# Representation is where Ambassador is from Country (as Represented Country) to Country and Diplomat has DiplomatName
  belongs_to :ambassador, :child_key => [:ambassador_name], :parent_key => [:diplomat_name]	# Ambassador is involved in Representation
  property :represented_country_name, String, :required => true, :key => true	# Representation is where Ambassador is from Country (as Represented Country) to Country and Country has CountryName
  property :country_name, String, :required => true, :key => true	# Representation is where Ambassador is from Country (as Represented Country) to Country and Country has CountryName
end

