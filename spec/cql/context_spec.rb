#
# ActiveFacts CQL Business Context Note tests
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#

require 'activefacts/support'
require 'activefacts/api/support'
require 'activefacts/cql/compiler'

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
      1, 'because'
    ],
    [ 'each Person occurs one time in Person is employed, Person is unemployed (as opposed to blah!);',
      1, 'as_opposed_to'
    ],
    [ 'for each Person at least one of these holds: Person is employed, Person is a bad credit risk (so that blah);',
      1, 'so_that'
    ],
    [ 'Person is good credit risk only if Person is employed (to avoid lending to people who can\'t repay);',
      1, 'to_avoid'
    ],
    [ 'Person is good credit risk if and only if Person is employed (to avoid lending to people who can\'t repay);',
      1, 'to_avoid'
    ],
    [ 'Person is good credit risk if and only if Person is employed (to avoid lending to people who can\'t repay, as agreed by Jim);',
      1, 'to_avoid', nil, ['Jim']
    ],
    # Entity and Fact types
    # Entity and Fact types
    [ 'Foo is identified by Bar [independent] where Foo has one Bar (so that we have an id);',
      1, 'so_that'
    ],
    [ 'Baz has one Bar (so that we have an id), Bar is of one Baz (because we need that);',
      2
    ],
    # REVISIT: No context notes on quantifiers yet
    # As agreed by:
    [ 'for each Person at least one of these holds: Person is employed, Person is a bad credit risk (so that blah, as agreed by Jim);',
      1, 'so_that', nil, ['Jim']
    ],
    # REVISIT: Populate an "as agreed by" with a date
    [ 'for each Person at least one of these holds: Person is employed, Person is a bad credit risk (so that blah, as agreed on 10-04-10 by Jim);',
      1, 'so_that', nil, ['Jim'], '10-04-10'
    ],
    # According to:
    [ 'for each Person at least one of these holds: Person is employed, Person is a bad credit risk (according to jim, so that blah);',
      1, 'so_that', ['jim']
    ],
  ]

  before :each do
    @compiler = ActiveFacts::CQL::Compiler.new('Test')
  end

  Notes.each do |c|
    source, count, kind, according_to, agreed_by, agreed_date = *c
    it "should parse #{source.inspect}" do

      result =
        begin
          @compiler.compile(ContextNotePrefix+source)
        rescue => e
          puts "#{e}:\n\t#{e.backtrace*"\n\t"}"
        end
      puts @compiler.failure_reason unless result
      result.should_not be_nil
      constellation = @compiler.vocabulary.constellation

      # constellation.ContextNote.each{|k,cn| puts "#{k.inspect} => #{cn.inspect}" }
      constellation.ContextNote.size.should == (count || 1)
      context_note = constellation.ContextNote.values[0]
      context_note.context_note_kind.should == kind if kind
      context_note.all_context_according_to.map{|cat| cat.agent.agent_name }.sort.should == according_to if according_to
      # context_note.discussion.should == discussion if discussion
      context_note.agreement.should_not be_nil if agreed_by || agreed_date
      context_note.agreement.all_context_agreed_by.map{|cab| cab.agent.agent_name}.sort.should == agreed_by if agreed_by
      context_note.agreement.date.should == Date.parse(agreed_date) if agreed_date
    end
  end
end
