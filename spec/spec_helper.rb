#
# A Custom Matcher for RSpec that shows the difference between two multi-line strings.
#
# Usage:
#   actual_text.should_not differ_from(expected_text)
#

require 'spec/helpers/diff_matcher'
require 'spec/helpers/array_matcher'
require 'spec/helpers/file_matcher'
require 'spec/helpers/string_matcher'

class String
  def strip_comments()
    c_comment = %r{/\*((?!\*/).)*\*/}m
    gsub(c_comment, '').gsub(%r{\n\n+},"\n")
  end
end

class Array
  def diff_strings(a2)
    d = Diff::LCS::diff(self, a2)
    d.map do |chunk|
      added_at = (add = chunk.detect{|d| d.action == '+'}) && add.position+1
      removed_at = (remove = chunk.detect{|d| d.action == '-'}) && remove.position+1
      "Line #{added_at}/#{removed_at}:\n"+
      chunk.map do |change|
        "#{change.action} #{change.element}"
      end*"\n"
    end*"\n"
  end
end
