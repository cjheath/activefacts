#
# ActiveFacts tests: Test the CQL parser by looking at its parse trees.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'activefacts/support'
require 'activefacts/api/support'
require 'activefacts/input/cql'

describe "Sample data" do
  SamplePrefix = %q{
  vocabulary V;

  CompanyName is written as String;
  Company is identified by its Name;
  Person is identified by its Name where Person is called PersonName;
  Directorship is where
      Company is directed by Person;
  }

  Samples = [
    [   # A simple ValueType instance
      "CompanyName 'Microsoft';",
      [{:facts=>[], :instances=>["CompanyName 'Microsoft'"]}]
    ],
    [   # Re-assert the same instance
      "CompanyName 'Microsoft'; CompanyName 'Microsoft';",
      [{:facts=>[], :instances=>["CompanyName 'Microsoft'"]}]
    ],
    [   # The same instance, but in a named population
      "example: CompanyName 'Microsoft';",
      [{:facts=>[], :instances=>["CompanyName 'Microsoft'"]}]
    ],
    [   # A simply-identified EntityType instance
      "Company 'Microsoft';",
      [{:facts=>["Company has CompanyName 'Microsoft'"], :instances=>["Company is identified by CompanyName where Company has CompanyName 'Microsoft'", "CompanyName 'Microsoft'"]}]
    ],
    [   # Re-assert the same instance
      "Company 'Microsoft'; Company 'Microsoft';",
      [{:facts=>["Company has CompanyName 'Microsoft'"], :instances=>["Company is identified by CompanyName where Company has CompanyName 'Microsoft'", "CompanyName 'Microsoft'"]}]
    ],
    [   # The same instance in a named population
      "example: Company 'Microsoft';",
      [{:facts=>["Company has CompanyName 'Microsoft'"], :instances=>["Company is identified by CompanyName where Company has CompanyName 'Microsoft'", "CompanyName 'Microsoft'"]}]
    ],
    [   # The Company instance asserted with an explicit identifying fact
      "Company has CompanyName 'Microsoft';",
      [{:facts=>["Company has CompanyName 'Microsoft'"], :instances=>["Company is identified by CompanyName where Company has CompanyName 'Microsoft'", "CompanyName 'Microsoft'"]}]
    ],
    [   # The Company instance asserted with an joined identifying instance
      "Company has CompanyName, CompanyName 'Microsoft';",
      [{:facts=>["Company has CompanyName 'Microsoft'"], :instances=>["Company is identified by CompanyName where Company has CompanyName 'Microsoft'", "CompanyName 'Microsoft'"]}]
    ],
    [   # The same, with an explicit identifying instance join
      "CompanyName 'Microsoft', Company has CompanyName;",
      [{:facts=>["Company has CompanyName 'Microsoft'"], :instances=>["Company is identified by CompanyName where Company has CompanyName 'Microsoft'", "CompanyName 'Microsoft'"]}]
    ],
    [   # A simple fact instance with two simply-identified entities
      "Company 'Microsoft' is directed by Person 'Gates';",
      [{:facts=>["Company has CompanyName 'Microsoft'", "Company is directed by Person", "Person is called PersonName 'Gates'"], :instances=>["Company is identified by CompanyName where Company has CompanyName 'Microsoft'", "CompanyName 'Microsoft'", "Directorship where Company is directed by Person", "Person is identified by PersonName where Person is called PersonName 'Gates'", "PersonName 'Gates'"]}]
    ],
    [   # Same with an explicit joined fact
      "Company 'Microsoft' is directed by Person, Person is called PersonName 'Gates';",
      [{:facts=>["Company has CompanyName 'Microsoft'", "Company is directed by Person", "Person is called PersonName 'Gates'"], :instances=>["Company is identified by CompanyName where Company has CompanyName 'Microsoft'", "CompanyName 'Microsoft'", "Directorship where Company is directed by Person", "Person is identified by PersonName where Person is called PersonName 'Gates'", "PersonName 'Gates'"]}]
    ],
    [   # Same with explicitly joined facts and instances
      "Company is directed by Person, Person is called PersonName, PersonName 'Gates', Company has CompanyName, CompanyName 'Microsoft';",
      [{:facts=>["Company has CompanyName 'Microsoft'", "Company is directed by Person", "Person is called PersonName 'Gates'"], :instances=>["Company is identified by CompanyName where Company has CompanyName 'Microsoft'", "CompanyName 'Microsoft'", "Directorship where Company is directed by Person", "Person is identified by PersonName where Person is called PersonName 'Gates'", "PersonName 'Gates'"]}]
    ],
    [   # Same in a named population
      "example: Company is directed by Person, Person is called PersonName, PersonName 'Gates', Company has CompanyName, CompanyName 'Microsoft';",
      [{:facts=>["Company has CompanyName 'Microsoft'", "Company is directed by Person", "Person is called PersonName 'Gates'"], :instances=>["Company is identified by CompanyName where Company has CompanyName 'Microsoft'", "CompanyName 'Microsoft'", "Directorship where Company is directed by Person", "Person is identified by PersonName where Person is called PersonName 'Gates'", "PersonName 'Gates'"]}]
    ],
  ]

  # REVISIT: This code does a better job than verbalise. Consider incorporating it?
  def instance_name(i)
    if i.is_a?(ActiveFacts::Metamodel::Fact)
      fact = i
      reading = fact.fact_type.preferred_reading
      reading_roles = reading.role_sequence.all_role_ref.sort_by{|rr| rr.ordinal}.map{|rr| rr.role }
      role_values_in_reading_order = fact.all_role_value.sort_by{|rv| reading_roles.index(rv.role) }
      instance_verbalisations = role_values_in_reading_order.map do |rv|
        next nil unless v = rv.instance.value
        v.to_s
      end
      return reading.expand([], false, instance_verbalisations)
      # REVISIT: Include the instance_names of all role players
    end

    if i.concept.is_a?(ActiveFacts::Metamodel::ValueType)
      return "#{i.concept.name} #{i.value}"
    end

    if i.concept.fact_type      # An instance of an objectified fact type
      return "#{i.concept.name} where #{instance_name(i.fact)}"
    end

    # It's an entity that's not an objectified fact type
    # REVISIT: If it has a simple identifier, there's no need to fully verbalise the identifying facts
    pi = i.concept.preferred_identifier
    identifying_role_refs = pi.role_sequence.all_role_ref.sort_by{|rr| rr.ordinal}
    return "#{i.concept.name}" +
      " is identified by " +
      identifying_role_refs.map do |rr|
        [ (l = rr.leading_adjective) ? l+"-" : nil,
          rr.role_name || rr.role.concept.name,
          (t = rr.trailing_adjective) ? l+"-" : nil
        ].compact*""
      end * " and " +
      " where " +
      identifying_role_refs.map do |rr|  # Go through the identifying roles and emit the facts that define them
        instance_role = i.concept.all_role.detect{|r| r.fact_type == rr.role.fact_type}
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
        :instances => popvalue.all_instance.map { |i| instance_name(i) }.sort,
        :facts => popvalue.all_fact.map { |fact| instance_name(fact) }.sort
      }
    end
  end

  Samples.each do |c|
    source, expected = *Array(c)
    it "should handle #{source.inspect}" do
      @text = SamplePrefix+source
      @vocabulary = ActiveFacts::Input::CQL.readstring(@text)
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
      @vocabulary = ActiveFacts::Input::CQL.readstring(@text)
      result = instance_data(@vocabulary)
      result[0].should == expected[0]
    end
  end
end
