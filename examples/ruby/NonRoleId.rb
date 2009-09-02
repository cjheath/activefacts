require 'activefacts/api'

module ::NonRoleId

  class ComparisonId < AutoCounter
    value_type 
  end

  class Ordinal < AutoCounter
    value_type 
  end

  class Comparison
    identified_by :comparison_id
    has_one :larger_ordinal, :class => Ordinal, :mandatory => true  # See Ordinal.all_comparison_as_larger_ordinal
    has_one :ordinal, :mandatory => true        # See Ordinal.all_comparison
    one_to_one :comparison_id, :mandatory => true  # See ComparisonId.comparison
  end

end
