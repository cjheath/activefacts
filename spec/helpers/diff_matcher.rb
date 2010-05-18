require 'pathname'

module DiffMatcher
  class DifferFrom
    def initialize(expected)
      case expected
      when Pathname
        @matcher = FileMatcher::BeDifferentFile.new(expected)
      when Array
        @matcher = ArrayMatcher::BeDifferentArray.new(expected)
      when String
        @matcher = FileMatcher::BeDifferentFile.new(expected)
      else
        raise "DiffMatcher doesn't know how to match a #{expected.class}"
      end
    end

    def matches?(actual)
      @matcher.matches?(actual)
    end

    def failure_message
      @matcher.failure_message
    end

    def negative_failure_message
      @matcher.negative_failure_message
    end
  end

  def differ_from(expected)
    DifferFrom.new(expected)
  end
end

Spec::Runner.configure do |config|
  config.include(DiffMatcher)
end
