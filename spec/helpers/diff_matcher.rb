require 'pathname'

require 'rspec/matchers'

class RSpec::Matchers::DSL::Matcher
  attr_writer :expected
end

RSpec::Matchers.define :differ_from do |expected|
  match do |actual|
    case expected
    when Pathname
      @m = have_different_contents
      @m.expected = expected
      @m.matches?(actual)
    when Array
      # If we pass "expected" here, it expects an array.
      # Works here, but not for Pathname or String
      # Hence the need for the attr_writer hack above.
      @m = be_different_array_from
      @m.expected = expected
      @m.matches?(actual)
    when String
      @m = have_different_contents
      @m.expected = expected
      @m.matches?(actual)
    else
      raise "DiffMatcher doesn't know how to match a #{expected.class}"
    end
  end

  failure_message_for_should do |actual|
    @m.failure_message_for_should
  end

  failure_message_for_should_not do |actual|
    @m.failure_message_for_should_not
  end
end
