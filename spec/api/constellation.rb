#
# ActiveFacts tests: Constellation instances in the Runtime API
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
describe "A Constellation instance" do
  setup do
    unless Object.const_defined?("M3")  # Is there a way to do once-only setup?
      module M3
        class Name < String
          value_type
          has_one :attr, Name
        end

        class Named
          identified_by :name
          has_one :name
        end

        class Person
          identified_by :given_name, :family_name
          has_one :given_name, :Name
          has_one :family_name, :Name
        end
      end
    end
    @constellation = ActiveFacts::Constellation.new(M3)   # REVISIT: Use a real Query, not 97
  end

  it "should support fetching its vocabulary and query" do
    @constellation.vocabulary.should == M3
  end

  it "should support methods to construct instances of any concept" do
    c = nil
    lambda {
        c = @constellation.Name("foo")
      }.should_not raise_error
    c.class.should == M3::Name
    c.constellation.should == @constellation
  end

  it "should re-use value instances constructed the same way" do
    bar1 = @constellation.Name("bar")
    bar2 = @constellation.Name("bar")
    bar1.object_id.should == bar2.object_id
  end

  it "should index value instances" do
    bar1 = @constellation.Name("baz")
    @constellation.instances[M3::Name].keys.sort.should == ["baz"]
  end

  it "should re-use entity instances constructed the same way" do
    bar = @constellation.Name("bar")
    bar1 = @constellation.Named(bar)
    bar2 = @constellation.Named(bar)
    bar1.object_id.should == bar2.object_id
  end

  it "should index entity instances" do
    bar = @constellation.Name("baz")
    bar1 = @constellation.Named(bar)
    @constellation.instances[M3::Named].keys.sort.should == [["baz"]]
  end

  it "should re-use entity instances constructed the same way with 2-part PI" do
    given = @constellation.Name("Fred")
    family = @constellation.Name("Fly")
    bar1 = @constellation.Person(given, family)
    bar2 = @constellation.Person(given, family)
    bar1.object_id.should == bar2.object_id
  end

  it "should index entity instances with 2-part PI" do
    given = @constellation.Name("Fred")
    family = @constellation.Name("Fly")
    bar1 = @constellation.Person(given, family)
    @constellation.instances[M3::Person].keys.sort.should == [["Fred","Fly"]]
  end

end
