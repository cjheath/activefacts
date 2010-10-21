module RSpec
  module Matchers
    class ArrayMatcher < Matcher
      def initialize expected
        super(:be_different_array_from, expected) do |*_expected|
          match_for_should do |actual|
            perform_match(actual, _expected[0])
            @extra + @missing != []
          end

          match_for_should_not do |actual|
            perform_match(actual, _expected[0])
            @extra + @missing == []
          end

          def perform_match(actual, expected)
            @extra = actual - expected
            @missing = expected - actual
          end

          def failure_message_for_should
            "expected a difference in the two lists, but got none"
          end

          failure_message_for_should_not do |actual|
            "expected no difference, but result #{
              [ (@missing.empty? ? nil : 'lacks '+@missing.sort.inspect),
                (@extra.empty? ? nil : 'has extra '+@extra.sort.inspect)
              ].compact * ' and '
            }"
          end
        end
      end
    end

    def be_different_array_from(expected)
      ArrayMatcher.new(expected)
    end
  end
end
