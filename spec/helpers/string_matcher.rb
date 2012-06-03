require 'diff/lcs'

RSpec::Matchers.define :have_different_contents do |x|
  match do |actual|
    perform_match(actual, expected)
  end

  def perform_match(actual, expected)
    expected_lines = expected.scan(/[^\n]+/)
    actual_lines = actual.scan(/[^\n]+/)
    differences = Diff::LCS::diff(expected_lines, actual_lines)
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

  failure_message_for_should do |actual|
    "expected a difference, but got none"
  end

  failure_message_for_should_not do |actual|
    "expected no difference, but got:\n#{@diff}"
  end
end
