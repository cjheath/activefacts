#
# ActiveFacts tests: Test the CQL parser by looking at its parse trees.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'activefacts/support'
require 'activefacts/api/support'
require 'activefacts/input/cql'

require 'set'

describe "Sample data" do
  SamplePrefix = %q{
  vocabulary V;

  Company Name is written as String;
  Date is written as Date;
  Company is identified by its Name;
  Person is identified by its Name where Person is called Person Name;
  Directorship is where
      Company is directed by Person;
  Directorship began on appointment-Date;
  }

  GoodSamples = [
    [   # A simple ValueType instance
      "Company Name 'Microsoft';",
      [{:facts=>Set[], :instances=>Set["Company Name 'Microsoft'"]}]
    ],
    [   # Re-assert the same instance
      "Company Name 'Microsoft'; Company Name 'Microsoft';",
      [{:facts=>Set[], :instances=>Set["Company Name 'Microsoft'"]}]
    ],
    [   # The same instance, but in a named population
      "example: Company Name 'Microsoft';",
      [{:facts=>Set[], :instances=>Set["Company Name 'Microsoft'"]}]
    ],
    [   # A simply-identified EntityType instance
      "Company 'Microsoft';",
      [{:facts=>Set["Company has Company Name 'Microsoft'"], :instances=>Set["Company is identified by Company Name where Company has Company Name 'Microsoft'", "Company Name 'Microsoft'"]}]
    ],
    [   # Re-assert the same instance
      "Company 'Microsoft'; Company 'Microsoft';",
      [{:facts=>Set["Company has Company Name 'Microsoft'"], :instances=>Set["Company is identified by Company Name where Company has Company Name 'Microsoft'", "Company Name 'Microsoft'"]}]
    ],
    [   # The same instance in a named population
      "example: Company 'Microsoft';",
      [{:facts=>Set["Company has Company Name 'Microsoft'"], :instances=>Set["Company is identified by Company Name where Company has Company Name 'Microsoft'", "Company Name 'Microsoft'"]}]
    ],
    [   # The Company instance asserted with an explicit identifying fact
      "Company has Company Name 'Microsoft';",
      [{:facts=>Set["Company has Company Name 'Microsoft'"], :instances=>Set["Company is identified by Company Name where Company has Company Name 'Microsoft'", "Company Name 'Microsoft'"]}]
    ],
    [   # The Company instance asserted with a related identifying instance
      "Company has Company Name, Company Name 'Microsoft';",
      [{:facts=>Set["Company has Company Name 'Microsoft'"], :instances=>Set["Company is identified by Company Name where Company has Company Name 'Microsoft'", "Company Name 'Microsoft'"]}]
    ],
    [   # The same, with an explicit identifying value step
      "Company Name 'Microsoft', Company has Company Name;",
      [{:facts=>Set["Company has Company Name 'Microsoft'"], :instances=>Set["Company is identified by Company Name where Company has Company Name 'Microsoft'", "Company Name 'Microsoft'"]}]
    ],
    [   # A simple fact instance with two simply-identified entities
      "Company 'Microsoft' is directed by Person 'Gates';",
      [{:facts=>Set["Company has Company Name 'Microsoft'", "Company is directed by Person", "Person is called Person Name 'Gates'"], :instances=>Set["Company is identified by Company Name where Company has Company Name 'Microsoft'", "Company Name 'Microsoft'", "Directorship where Company is directed by Person", "Person is identified by Person Name where Person is called Person Name 'Gates'", "Person Name 'Gates'"]}]
    ],
    [   # Same with an explicit joined fact
      "Company 'Microsoft' is directed by Person, Person is called Person Name 'Gates';",
      [{:facts=>Set["Company has Company Name 'Microsoft'", "Company is directed by Person", "Person is called Person Name 'Gates'"], :instances=>Set["Company is identified by Company Name where Company has Company Name 'Microsoft'", "Company Name 'Microsoft'", "Directorship where Company is directed by Person", "Person is identified by Person Name where Person is called Person Name 'Gates'", "Person Name 'Gates'"]}]
    ],
    [   # Same with explicitly joined facts and instances
      "Company is directed by Person, Person is called Person Name, Person Name 'Gates', Company has Company Name, Company Name 'Microsoft';",
      [{:facts=>Set["Company has Company Name 'Microsoft'", "Company is directed by Person", "Person is called Person Name 'Gates'"], :instances=>Set["Company is identified by Company Name where Company has Company Name 'Microsoft'", "Company Name 'Microsoft'", "Directorship where Company is directed by Person", "Person is identified by Person Name where Person is called Person Name 'Gates'", "Person Name 'Gates'"]}]
    ],
    [   # Same in a named population
      "example: Company is directed by Person, Person is called Person Name, Person Name 'Gates', Company has Company Name, Company Name 'Microsoft';",
      [{:facts=>Set["Company has Company Name 'Microsoft'", "Company is directed by Person", "Person is called Person Name 'Gates'"], :instances=>Set["Company is identified by Company Name where Company has Company Name 'Microsoft'", "Company Name 'Microsoft'", "Directorship where Company is directed by Person", "Person is identified by Person Name where Person is called Person Name 'Gates'", "Person Name 'Gates'"]}]
    ],

    # Objectification examples
    [
      "Directorship (where Company 'Microsoft' is directed by Person 'Gates');",
      [{:facts=>Set["Company has Company Name 'Microsoft'", "Company is directed by Person", "Person is called Person Name 'Gates'"], :instances=>Set["Person is identified by Person Name where Person is called Person Name 'Gates'", "Company is identified by Company Name where Company has Company Name 'Microsoft'", "Company Name 'Microsoft'", "Directorship where Company is directed by Person", "Person Name 'Gates'"]}]
    ],
    [
      "Directorship (where Company 'Microsoft' is directed by Person 'Gates') began on appointment Date '20/02/1981';",
      [{:facts=>Set["Company has Company Name 'Microsoft'", "Company is directed by Person", "Directorship began on appointment-Date '20/02/1981'", "Person is called Person Name 'Gates'"], :instances=>Set["Person is identified by Person Name where Person is called Person Name 'Gates'", "Company is identified by Company Name where Company has Company Name 'Microsoft'", "Company Name 'Microsoft'", "Directorship where Company is directed by Person", "Person Name 'Gates'", "Date '20/02/1981'"]}]
    ],
  ]

  BadSamples =
  [
    [
      "Company Name",
      "Company Name",
    ],
    [
      "foo: Company Name",
      "Company Name",
    ],
    [ # Omit the company name:
      "example: Company is directed by Person, Person is called Person Name, Person Name 'Gates', Company has Company Name;",
      [ "Company (lacking Company Name)", "Company Name (needs a value)" ]
    ],
  ]

  def render_value v
    if v.to_s !~ /[^-+0-9.]/ and (n = eval(v.to_s) rescue nil)
      n
    else
      "'"+v.to_s.gsub(/'/,'\\\'')+"'"
    end
  end

  # REVISIT: This code does a better job than verbalise. Consider incorporating it?
  def instance_name(i)
    if i.is_a?(ActiveFacts::Metamodel::Fact)
      fact = i
      reading = fact.fact_type.preferred_reading
      reading_roles = reading.role_sequence.all_role_ref.sort_by{|rr| rr.ordinal}.map{|rr| rr.role }
      role_values_in_reading_order = fact.all_role_value.sort_by{|rv| reading_roles.index(rv.role) }
      instance_verbalisations = role_values_in_reading_order.map do |rv|
        next nil unless v = rv.instance.value
        render_value(v)
      end
      return reading.expand([], false, instance_verbalisations)
      # REVISIT: Include the instance_names of all role players
    end

    if i.object_type.is_a?(ActiveFacts::Metamodel::ValueType)
      return "#{i.object_type.name} #{render_value(i.value)}"
    end

    if i.object_type.fact_type      # An instance of an objectified fact type
      return "#{i.object_type.name} where #{instance_name(i.fact)}"
    end

    # It's an entity that's not an objectified fact type
    # REVISIT: If it has a simple identifier, there's no need to fully verbalise the identifying facts
    pi = i.object_type.preferred_identifier
    identifying_role_refs = pi.role_sequence.all_role_ref.sort_by{|rr| rr.ordinal}
    return "#{i.object_type.name}" +
      " is identified by " +
      identifying_role_refs.map do |rr|
        [ (l = rr.leading_adjective) ? l+"-" : nil,
          rr.role.role_name || rr.role.object_type.name,
          (t = rr.trailing_adjective) ? l+"-" : nil
        ].compact*""
      end * " and " +
      " where " +
      identifying_role_refs.map do |rr|  # Go through the identifying roles and emit the facts that define them
        instance_role = i.object_type.all_role.detect{|r| r.fact_type == rr.role.fact_type}
        identifying_fact = i.all_role_value.detect{|rv| rv.fact.fact_type == rr.role.fact_type}.fact
        #counterpart_role = (rr.role.fact_type.all_role.to_a-[instance_role])[0]
        #identifying_instance = counterpart_role.all_role_value.detect{|rv| rv.fact == identifying_fact}.instance
        instance_name(identifying_fact)
      end*", "
  end

  def instance_data(populations)
    populations = @vocabulary.constellation.Population
    populations.keys.sort.map do |popname|
      popvalue = populations[popname]
      {
        :instances => Set[*popvalue.all_instance.map { |i| instance_name(i) }],
        :facts => Set[*popvalue.all_fact.map { |fact| instance_name(fact) }]
      }
    end
  end

  # [].
  GoodSamples.
  each do |c|
    source, expected = *Array(c)

    it "should handle #{source.inspect}" do
      @text = SamplePrefix+source
      #pending if expected == [:pending]
      exception = nil
      lambda do
        begin
          @vocabulary = ActiveFacts::Input::CQL.readstring(@text)
        rescue => exception
          if debug :exception
            puts "#{exception.message}"
            puts "\t#{exception.backtrace*"\n\t"}"
          end
          raise
        end
      end.should_not raise_error
      result = instance_data(@vocabulary)

      if expected
        result[0].should == expected[0]
      else
        pending "#{source}:\n\t#{result.inspect}"
      end
    end

    it "should de-duplicate #{source.inspect}" do
      # Make sure you don't get anything duplicated
      @text = SamplePrefix+source+source
      #pending if expected == [:pending]
      exception = nil
      lambda do
        begin
          @vocabulary = ActiveFacts::Input::CQL.readstring(@text)
        rescue => exception
          if debug :exception
            puts "#{exception.message}"
            puts "\t#{exception.backtrace*"\n\t"}"
          end
          raise
        end
      end.should_not raise_error
      result = instance_data(@vocabulary)
      result[0].should == expected[0]
    end

  end

  BadSamples.each do |c|
    source, missing = *Array(c)
    it "should detect missing queries in #{source.inspect}" do
      @text = SamplePrefix+source
      lambda do
        begin
          @vocabulary = ActiveFacts::Input::CQL.readstring(@text)
        rescue => @exception
          raise
        end
      end.should raise_error

      if missing
        Array(missing).each do |m|
          @exception.message.should =~ (m.is_a?(Regexp) ? m : Regexp.new(Regexp.escape(m)))
        end
      else
        pending "raised #{@exception}"
      end
    end
  end

end
