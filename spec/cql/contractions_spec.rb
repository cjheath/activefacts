#
# ActiveFacts CQL Fact Type matching tests - contractions.
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
# Contractions are where a fact type clause is followed by another (with
# some conjunction except for comparisons) with one player *implicit* in
# the following clause.
#
# Right contraction elides the repetition of the right-most player,
# and left contraction elides the left-most player.
#
# So, using the notation "A rel B" for binaries,
# "A relA B relA C" for ternaries, and "C prop" for properties,
# we can write equivalences as follows.
#
# Note 1: Terms may be more than one word.
# Note 2: For any "A rel B", the example also applies to a ternary or
#       higher, as appropriate.

=begin
Right contractions with 'and':
  A rel B and B prop
    -> A rel B who/that prop
  E.g. Person pats Cat that is asleep

  A rel B and B rel2 C
    -> A rel B who/that rel2 C
  E.g. Person pats Cat that is lying on Mat

  A rel B and B rel2A C rel2A D
    -> A rel B who/that rel2A C rel2B D
  E.g. Person pats Cat that ate Food at Time

  A rel B and B > C
    -> A rel B > C
  E.g. Person is of Age >= 21

  A > B and B rel C
    -> A > B rel C
  E.g. 21 > Age of Person

Right contractions with ',':
  A rel B, B rel2 C
    -> A rel B who/that rel2 C

  A rel B, B prop
    -> A rel B who/that prop

  A rel B, B > C
    -> A rel B > C

  A > B, B rel C
    -> A > B rel C

Left contractions with 'and':
  A rel B and A rel2 C
    -> A rel B and rel2 C
  E.g. Boy seduces Girl and is drunk
  
  A rel B and A prop
    -> A rel B and prop

  A rel B and A > C
    -> A rel B and > C

Left contractions with 'or':
  A rel B or A rel2 C
    -> A rel B or rel2 C
  
  A rel B or A prop
    -> A rel B or prop

  A rel B or A > C
    -> A rel B or > C

  A > B or A rel C
    -> A > B or rel C

Double contractions (not supported in CQL yet):
  A rel B and A rel2 B
    -> A rel B and rel2
  E.g. Person came to Party and was invited to

Extended contractions (not supported in CQL yet) (note the ambiguity - if allowed, the first takes precedence!):
  A rel B and B rel2 C and B prop
    -> A rel B that rel2 C and prop
  E.g. LazyDogOwner is a Person who owns Dog that barks and Dog is lazy.

  A rel B and B rel2 C and A prop
    -> A rel B that rel2 C and prop
  E.g. LazyDogOwner is a Person who owns Dog that barks and Person is lazy.

And/or resolution:
  A rel B and B rel2 C or A rel3 D
  A rel B and B rel2 C or B rel3 D  -> Logical, A must rel B but B can carry either rel
  A rel B and B rel2 C or C rel3 D  -> Illogical form (mandates B rel2 C so 'or' is meaningless)

Ambiguous, disallowed:
  A > 2 + B > C

Comments from Matt on contraction and verbalisation:

I have two types of list phrases which I classify as 'header' and 'inline'.
And and or are inline, the other four (negated and/or, positive or negative
xor) all use header forms. There is also a header form of negation (it is not
true that...). The header forms (all of the following must be true: etc) can
introduce vars in the starting context, but not those introduced by previous
elements in the list.

You'll likely need something similar, though, on nested expressions. You also
have to decide where your implicit existential placement is if you use the
same var in multiple branches or under negation. Lots of fun stuff.

=end


require 'rspec/expectations'

require 'activefacts/support'
require 'activefacts/api/support'
require 'activefacts/cql/compiler'
require File.dirname(__FILE__) + '/../helpers/compile_helpers'  # Can't see how to include/extend these methods correctly

describe "When compiling a query, " do
  before :each do
    extend CompileHelpers

    prefix = %q{
      vocabulary Tests;
      Boy is written as String;
      Girl is written as Integer;
      Age is written as Integer;
      Boy is of Age;
      Boy is going out with Girl, Girl is going out with Boy;
    }
    @compiler = ActiveFacts::CQL::Compiler.new('Test')
    @compiler.compile(prefix)
    @constellation = @compiler.vocabulary.constellation

    baseline

    def self.compile string
      lambda {
        @compiler.compile string
      }.should_not raise_error
    end
  end

  shared_examples_for "single contractions" do
    it "should produce one fact type" do
      (new_fact_types = fact_types).size.should == 1
    end
    it "the fact type should have one reading" do
      fact_type = fact_types[0]
      fact_type.all_reading.size.should == 1
    end
    it "the fact type should have no presence constraints" do
      fact_type = fact_types[0]
      (pcs = fact_pcs(fact_type)).size.should == 0
    end
    it "should produce one query" do
      fact_type = fact_types[0]
      query = derivation(fact_type)
    end
    it "the query should have 3 variables" do
      fact_type = fact_types[0]
      query = derivation(fact_type)
      variables = query.all_variable.to_a
      variables.size.should == 3
    end
    it "the query should have 2 steps" do
      fact_type = fact_types[0]
      query = derivation(fact_type)
      steps = query.all_step.to_a
      steps.size.should == 2
    end

    it "and should project the fact type roles from the query" do
      pending "Plays are not yet projected" do
        query = derivation(fact_type)
        queries = fact_type.all_role.map{|r| r.all_play.map{|play| play.query}}.flatten.uniq
        queries.size == 1
        queries.should == [query]
      end
    end
  end

  describe "right contractions having" do
    describe "a single contraction using 'who'" do
      before :each do
        compile %q{Boy is relevant where Girl is going out with Boy who is of Age; }
      end

      it_should_behave_like "single contractions"
    end

    describe "a single contraction using 'that'" do
      before :each do
        compile %q{Boy is relevant where Girl is going out with Boy that is of Age; }
      end

      it_should_behave_like "single contractions"
    end
  end

  describe "left contractions having" do
    describe "a single contraction" do
      before :each do
        compile %q{Boy is relevant where Boy is of Age and is going out with Girl; }
      end

      it_should_behave_like "single contractions"
    end
  end
end

=begin
Examples on the Blog model:

Post is nice where Post was written by Author and belongs to Topic and includes Ordinal paragraph;
Post is nice where Post was written by Author and belongs to Topic or Post includes Ordinal paragraph or has Post Id;
Post is nice where Post was written by Author and belongs to Topic or includes Ordinal paragraph;
Post is nice where Post was written by Author and belongs to Topic or Post includes Ordinal paragraph or has Post Id;
=end
