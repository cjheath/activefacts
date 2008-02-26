describe "Value Type instances" do
  setup do
    unless Object.const_defined?("M2")	# Is there a way to do once-only setup?
      module M2
	class Attr < Int
	  value_type
	end
	class StringValue < String
	  value_type
	  binary :attr
	end
      end
    end
    @string_value = M2::StringValue.new("value")
  end

  it "should respond to verbalise" do
    @string_value.respond_to?(:verbalise).should be_true
  end

  it "should verbalise correctly" do
    @string_value.verbalise.should == "StringValue 'value'"
  end

  it "should respond to constellation" do
    @string_value.respond_to?(:constellation).should be_true
  end

  it "should respond to query" do
    @string_value.respond_to?(:query).should be_true
    lambda {
	@string_value.query
      }.should_not raise_error
  end

  it "should respond to its roles" do
    @string_value.respond_to?(:attr).should be_true
    @string_value.respond_to?(:"attr=").should be_true
  end

  it "should allow its roles to be assigned" do
    lambda {
	@string_value.attr = 23
      }.should_not raise_error
  end

  it "should allow its roles to be assigned" do
      @string_value.attr = 23
      @string_value.attr.should == 23
  end

  it "should return the ValueType in response to .class()" do
      @string_value.class.vocabulary.should == M2
  end

end
