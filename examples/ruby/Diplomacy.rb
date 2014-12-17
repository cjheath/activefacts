require 'activefacts/api'

module ::Diplomacy

  class CountryName < String
    value_type 
    one_to_one :country                         # See Country.country_name
  end

  class DiplomatName < String
    value_type 
    one_to_one :diplomat                        # See Diplomat.diplomat_name
  end

  class LanguageName < String
    value_type 
    one_to_one :language                        # See Language.language_name
  end

  class Country
    identified_by :country_name
    one_to_one :country_name, :mandatory => true  # See CountryName.country
  end

  class Diplomat
    identified_by :diplomat_name
    one_to_one :diplomat_name, :mandatory => true  # See DiplomatName.diplomat
    has_one :represented_country, :class => Country, :mandatory => true  # See Country.all_diplomat_as_represented_country
    has_one :served_country, :class => Country, :mandatory => true  # See Country.all_diplomat_as_served_country
  end

  class Language
    identified_by :language_name
    one_to_one :language_name, :mandatory => true  # See LanguageName.language
  end

  class LanguageUse
    identified_by :language, :country
    has_one :country, :mandatory => true        # See Country.all_language_use
    has_one :language, :mandatory => true       # See Language.all_language_use
  end

  class Ambassador < Diplomat
  end

  class Fluency
    identified_by :diplomat, :language
    has_one :diplomat, :mandatory => true       # See Diplomat.all_fluency
    has_one :language, :mandatory => true       # See Language.all_fluency
  end

  class Representation
    identified_by :represented_country, :country
    has_one :ambassador, :mandatory => true     # See Ambassador.all_representation
    has_one :country, :mandatory => true        # See Country.all_representation
    has_one :represented_country, :class => Country, :mandatory => true  # See Country.all_representation_as_represented_country
  end

end
