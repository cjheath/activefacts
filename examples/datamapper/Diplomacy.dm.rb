require 'dm-core'
require 'dm-constraints'

class Country
  include DataMapper::Resource

  property :country_name, String, :key => true	# Country has CountryName
  has n, :diplomat_as_represented_country, 'Diplomat', :child_key => [:represented_country_name], :parent_key => [:country_name]	# Diplomat represents Country
  has n, :diplomat_as_served_country, 'Diplomat', :child_key => [:served_country_name], :parent_key => [:country_name]	# Diplomat serves in Country
  has n, :language_use, 'LanguageUse'	# Language is spoken in Country
  has n, :representation_as_represented_country, 'Representation', :child_key => [:represented_country_name], :parent_key => [:country_name]	# Ambassador is from Country to Country
  has n, :representation	# Ambassador is from Country to Country
end

class Diplomat
  include DataMapper::Resource

  property :represented_country_name, String, :required => true	# Diplomat represents Country and Country has CountryName
  belongs_to :represented_country, 'Country', :child_key => [:represented_country_name], :parent_key => [:country_name]	# Diplomat represents Country
  property :served_country_name, String, :required => true	# Diplomat serves in Country and Country has CountryName
  belongs_to :served_country, 'Country', :child_key => [:served_country_name], :parent_key => [:country_name]	# Diplomat serves in Country
  property :diplomat_name, String, :key => true	# Diplomat has DiplomatName
  has n, :fluency	# Diplomat speaks Language
end

class Ambassador < Diplomat
  has n, :representation, :child_key => [:ambassador_name], :parent_key => [:diplomat_name]	# Ambassador is from Country to Country
end

class Fluency
  include DataMapper::Resource

  property :diplomat_name, String, :key => true	# Fluency is where Diplomat speaks Language and Diplomat has DiplomatName
  belongs_to :diplomat	# Diplomat is involved in Fluency
  property :language_name, String, :key => true	# Fluency is where Diplomat speaks Language and Language has LanguageName
  belongs_to :language	# Language is involved in Fluency
end

class Language
  include DataMapper::Resource

  property :language_name, String, :key => true	# Language has LanguageName
  has n, :fluency	# Diplomat speaks Language
  has n, :language_use, 'LanguageUse'	# Language is spoken in Country
end

class LanguageUse
  include DataMapper::Resource

  property :country_name, String, :key => true	# LanguageUse is where Language is spoken in Country and Country has CountryName
  belongs_to :country	# Country is involved in LanguageUse
  property :language_name, String, :key => true	# LanguageUse is where Language is spoken in Country and Language has LanguageName
  belongs_to :language	# Language is involved in LanguageUse
end

class Representation
  include DataMapper::Resource

  property :ambassador_name, String, :key => true	# Representation is where Ambassador is from Country to Country and Diplomat has DiplomatName
  belongs_to :ambassador, :child_key => [:ambassador_name], :parent_key => [:diplomat_name]	# Ambassador is involved in Representation
  property :represented_country_name, String, :key => true	# Representation is where Ambassador is from Country to Country and Country has CountryName
  belongs_to :represented_country, 'Country', :child_key => [:represented_country_name], :parent_key => [:country_name]	# Represented_Country is involved in Representation
  property :country_name, String, :key => true	# Representation is where Ambassador is from Country to Country and Country has CountryName
  belongs_to :country	# Country is involved in Representation
end

