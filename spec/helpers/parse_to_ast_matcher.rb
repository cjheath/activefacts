require 'rspec/expectations'

require 'activefacts/cql'
require 'activefacts/support'
require 'activefacts/api/support'
require 'helpers/test_parser'

RSpec::Matchers.define :parse_to_ast do |*expected_asts|
  match do |actual|
    @parser = TestParser.new
    @result = @parser.parse_all(actual, :definition)

    # If the expected_asts is "false", treat this test as pending:
    throw :pending_declared_in_example, "Should parse #{actual.strip.inspect}" if expected_asts == [false]

    # If we failed to parse, fail and say why:
    return false unless @result

    # Otherwise compare the canonical form of the AST
    @canonical_form = @result.map{|d| d.ast.to_s}.map{|e| e.gsub(/\s+/,' ')}

    # If we weren't given an AST, this test is pending. Show what result we obtained:
    throw :pending_declared_in_example, actual.inspect+' should parse to ['+@canonical_form*', '+']' if expected_asts.empty?

    @canonical_form == (expected_asts.map{|e| e.gsub(/\s+/,' ') })
  end

  failure_message_for_should do
    if !@result
      @parser.failure_reason
    else
      "Expected #{expected_asts.inspect}\nbut got: #{@canonical_form.inspect}"
    end
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
