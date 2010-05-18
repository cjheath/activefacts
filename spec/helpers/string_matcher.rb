require 'diff/lcs'

module StringMatcher
  class BeDifferentString
    def initialize(expected)
      @expected = expected.scan(/[^\n]+/)
    end

    def matches?(actual)
      actual_lines = actual.scan(/[^\n]+/)
      differences = Diff::LCS::diff(@expected, actual_lines)
      @diff = differences.map do |chunk|
          added_at = (add = chunk.detect{|d| d.action == '+'}) && add.position+1
          removed_at = (remove = chunk.detect{|d| d.action == '-'}) && remove.position+1
          "Line #{added_at}/#{removed_at}:\n"+
          chunk.map do |change|
            "#{change.action} #{change.element}"
          end*"\n"
        end*"\n"
      @diff != ''
    end

    def failure_message
      "expected a difference, but got none"
    end

    def negative_failure_message
      "expected no difference, but got:\n#{@diff}"
    end
  end

  def have_different_contents(expected)
    BeDifferentString.new(expected)
  end
end

Spec::Runner.configure do |config|
  config.include(StringMatcher)
end
