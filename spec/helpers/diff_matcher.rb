require 'pathname'

module RSpec
  module Matchers
    def differ_from(expected)
      case expected
      when Pathname
        FileMatcher.new(expected)
      when Array
        ArrayMatcher.new(expected)
      when String
        FileMatcher.new(expected)
      else
        raise "DiffMatcher doesn't know how to match a #{expected.class}"
      end
    end
  end
end
