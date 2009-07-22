#
# ActiveFacts CQL Business Context Note tests
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'rubygems'
require 'treetop'
require 'activefacts/support'
require 'activefacts/api/support'
require 'activefacts/cql/parser'

describe "Business Context Notes" do
  # (according_to people ',')? (because / as_opposed_to / so_that / to_avoid) discussion (',' as_agreed_by)? s
  Prefix = %q{
    Person is written as Person;
  }
  Notes = [
    # Constraints:
    [ 'each Person occurs one time in Person is employed, Person is unemployed (because it can be no other way!);',
      nil
    ],
    [ 'each Person occurs one time in Person is employed, Person is unemployed (as opposed to blah!);',
      nil
    ],
    [ 'for each Person at least one of these holds: Person is employed, Person is a bad credit risk (so that blah);',
      nil
    ],
    [ 'Person is good credit risk only if Person is employed (to avoid lending to people who can\'t repay);',
      nil
    ],
    [ 'Person is good credit risk if and only if Person is employed (to avoid lending to people who can\'t repay);',
      nil
    ],
    # Entity and Fact types
    [ 'Foo is identified by Bar [independent] where Foo has one Bar (so that we have an id);',
      nil
    ],
    [ 'Foo has one Bar (so that we have an id), Bar is of one Foo (because we need that);',
      nil
    ],
    # REVISIT: No context notes on quantifiers yet
    # As agreed by:
    [ 'for each Person at least one of these holds: Person is employed, Person is a bad credit risk (so that blah, as agreed by Jim);',
      nil
    ],
    # REVISIT: Populate an "as agreed by" with a date
    [ 'for each Person at least one of these holds: Person is employed, Person is a bad credit risk (so that blah, as agreed on 29 March by Jim);',
      nil
    ],
    # According to:
    [ 'for each Person at least one of these holds: Person is employed, Person is a bad credit risk (according to jim, so that blah);',
      nil
    ],
  ]

  before :each do
    @parser = ActiveFacts::CQLParser.new
  end

  Notes.each do |c|
    source, ast = *[c].flatten
    it "should parse #{source.inspect}" do
      #debugger
      result = @parser.parse_all(Prefix+source, :definition)

      puts @parser.failure_reason unless result
      result.should_not be_nil
      result.map{|d| d.value}.should == ast if ast
      # Uncomment this to see what should replace "nil" in the cases above:
      #puts result.map{|d| d.value}.inspect unless ast
    end
  end
end
