#
# ActiveFacts CQL Business Context Note tests
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#

require 'activefacts/support'
require 'activefacts/api/support'
require 'activefacts/cql/compiler'
# require File.dirname(__FILE__) + '/../helpers/test_parser'

describe "Business Context Notes" do
  # (according_to people ',')? (because / as_opposed_to / so_that / to_avoid) discussion (',' as_agreed_by)? s
  ContextNotePrefix = %q{
    vocabulary Test;
    Person is written as Person;
    Person is employed;
    Person is unemployed;
    Person is a bad credit risk;
    Person is good credit risk;
    Bar is written as Bar;
    Baz is written as Baz;
  }
  Notes = [
    # Constraints:
    [ 'each Person occurs one time in Person is employed, Person is unemployed (because it can be no other way!);',
    ],
    [ 'each Person occurs one time in Person is employed, Person is unemployed (as opposed to blah!);',
    ],
    [ 'for each Person at least one of these holds: Person is employed, Person is a bad credit risk (so that blah);',
    ],
    [ 'Person is good credit risk only if Person is employed (to avoid lending to people who can\'t repay);',
    ],
    [ 'Person is good credit risk if and only if Person is employed (to avoid lending to people who can\'t repay);',
    ],
    # Entity and Fact types
    [ 'Foo is identified by Bar [independent] where Foo has one Bar (so that we have an id);',
    ],
    [ 'Baz has one Bar (so that we have an id), Bar is of one Baz (because we need that);',
    ],
    # REVISIT: No context notes on quantifiers yet
    # As agreed by:
    [ 'for each Person at least one of these holds: Person is employed, Person is a bad credit risk (so that blah, as agreed by Jim);',
    ],
    # REVISIT: Populate an "as agreed by" with a date
    [ 'for each Person at least one of these holds: Person is employed, Person is a bad credit risk (so that blah, as agreed on 29 March by Jim);',
    ],
    # According to:
    [ 'for each Person at least one of these holds: Person is employed, Person is a bad credit risk (according to jim, so that blah);',
    ],
  ]

  before :each do
    @compiler = ActiveFacts::CQL::Compiler.new(ContextNotePrefix)
  end

  Notes.each do |c|
    source, result = *c
    it "should parse #{source.inspect}" do

      result = @compiler.compile(source)
      puts @compiler.failure_reason unless result
      result.should_not be_nil
      constellation = @compiler.vocabulary.constellation

      # constellation.ContextNote.each{|k,cn| puts "#{k.inspect} => #{cn.inspect}" }
      constellation.ContextNote.size.should == 1
      context_note = constellation.ContextNote.values[0]
      if result
        # REVISIT: Put something sensible here after we have context note compilation again.
        # context_note.should be_like(result)
      else
        p context_note.description
      end
    end
  end
end
