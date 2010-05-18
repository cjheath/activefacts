require 'pathname'

module ArrayMatcher
  class BeDifferentArray
    def initialize(expected)
      @expected = expected
    end

    def matches?(actual)
      @extra = actual - @expected
      @missing = @expected - actual
      @extra + @missing != []   # Because the predicate is "be_different_array_from", the sense is inverted
    end

    def failure_message
      "expected a difference in the two lists, but got none"
    end

    def negative_failure_message
      "expected no difference, but result #{
        [ (@missing.empty? ? nil : 'lacks '+@missing.sort.inspect),
          (@extra.empty? ? nil : 'has extra '+@extra.sort.inspect)
        ].compact * ' and '
      }"
    end
  end

  def be_different_array_from(expected)
    BeDifferentArray.new(expected)
  end
end

Spec::Runner.configure do |config|
  config.include(ArrayMatcher)
end
