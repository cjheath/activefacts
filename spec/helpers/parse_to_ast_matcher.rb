require 'rspec/expectations'

require 'activefacts/cql'
require 'activefacts/support'
require 'activefacts/api/support'
require 'helpers/test_parser'

RSpec::Matchers.define :parse_to_ast do |*expected_asts|
  match do |actual|
    parser = TestParser.new
    result = parser.parse_all(actual, :definition)
    pending '"'+parser.failure_reason+'"' unless result
    @canonical_form = result.map{|d| d.ast.to_s}
    throw :pending_declared_in_example, actual.inspect+' should parse to ['+@canonical_form*', '+']' if expected_asts.empty?
    (@canonical_form.map{|e| e.gsub(/\s+/,' ')}) == (expected_asts.map{|e| e.gsub(/\s+/,' ') })
  end

  failure_message_for_should do
    "Expected #{expected_asts.inspect}\nbut got: #{@canonical_form.inspect}"
  end
end

RSpec::Matchers.define :fail_to_parse do |*error_regexp|
  match do |actual|
    parser = TestParser.new
    result = parser.parse_all(actual, :definition)
    result.should be_nil
    if error_regexp = error_regexp[0]
      parser.failure_reason.should =~ error_regexp
    else
      throw :pending_declared_in_example, actual.inspect+' fails, please add message pattern to match '+parser.failure_reason.inspect
    end
  end
end
