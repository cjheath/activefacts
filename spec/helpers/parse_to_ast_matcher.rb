require 'rspec/expectations'

require 'activefacts/cql'
require 'activefacts/support'
require 'activefacts/api/support'
require 'helpers/test_parser'

RSpec::Matchers.define :parse_to_ast do |*expected_asts|
  def canonicalise(s)
    if s.is_a?(Array)
      s.map{|e| canonicalise(e)}
    else
      s.to_s.gsub(/\s+/,' ')
    end
  end

  match do |actual|
    @parser = TestParser.new
    @result = @parser.parse_all(actual, :definition)

    # If the expected_asts is "false", treat this test as pending:
    if expected_asts == [false]
      if @result
        # Unfortunately there's no way to say why the failure was expected here
        # RSpec stores it in example.metadata[:execution_result][:pending_message]
        raise RSpec::Core::PendingExampleFixedError.new
      else
        throw :pending_declared_in_example, "Should parse #{actual.strip.inspect}"
      end
    end

    # If we failed to parse, fail and say why:
    next false unless @result

    # Otherwise compare the canonical form of the AST
    @canonical_form = @result.map{|d| canonicalise(d.ast)}

    # If we weren't given an AST, this test is pending. Show what result we obtained:
    throw :pending_declared_in_example, actual.inspect+' should parse to ['+@canonical_form*', '+']' if expected_asts.empty?

    @canonical_form == canonicalise(expected_asts)
  end

  failure_message_for_should do
    if !@result
      @parser.failure_reason
    else
      "Expected %q{#{canonicalise(expected_asts)}}\nbut got: %q{#{@canonical_form}}"
    end
  end
end

RSpec::Matchers.define :fail_to_parse do |*error_regexp|
  match do |actual|
    @parser = TestParser.new
    @actual = actual
    @result = @parser.parse_all(actual, :definition)
    @result.should be_nil
    if @re = error_regexp[0]
      @parser.failure_reason.should =~ @re
    else
      throw :pending_declared_in_example, actual.inspect+' fails, please add message pattern to match '+@parser.failure_reason.inspect
    end
  end

  failure_message_for_should do
    if @result
      @canonical_form = @result.map{|d| canonicalise(d.ast)}
      "Expected not to succeed in parsing #{actual.inspect}\nbut got #{@canonical_form.inspect}"
    else
      "Failed as expected in parsing #{actual.inspect}\n" +
        "but not for the right reason: #{@re.inspect}\n"+
        "got #{@parser.failure_reason.inspect}"
    end
  end
end
