#
# ActiveFacts CQL Fact Type matching tests
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
$: << Dir::getwd

require 'rspec/expectations'

require 'activefacts/support'
require 'activefacts/api/support'
require 'activefacts/cql/compiler'
require File.dirname(__FILE__) + '/../helpers/compile_helpers'

describe "When comparing roles of a reading with an existing reading" do
  before :each do
    extend CompileHelpers

    prefix = %q{
      vocabulary Tests;
      Boy is written as String;
      Girl is written as Integer;
    }
    @compiler = ActiveFacts::CQL::Compiler.new('Test')
    @compiler.compile(prefix)
    @constellation = @compiler.vocabulary.constellation

    baseline
  end

  describe "producing correct side effects" do
    before :each do
      @compiler.compile %q{ Boy is going out with Girl; }
      @simple_ft = fact_types[0]
      baseline
      @compiler.compile %q{ Boy dislikes ugly-Girl; }
      @ugly_ft = fact_types[0]
      baseline
      @compiler.compile %q{ Boy -monster hurts Girl; }
      @hurts_ft = fact_types[0]
      baseline
      #debug_enable("matching"); debug_enable("matching_fails"); debug_enable("parse")
    end
    after :each do
      # debug_disable("matching"); debug_disable("matching_fails"); debug_disable("parse")
    end

    it "should match exact reading" do
      parse %q{Boy is going out with Girl;}
      @asts.size.should == 1
      side_effects = match_readings_to_existing(@asts[0], @simple_ft.all_reading.single)
      side_effects[0].should_not be_nil
      side_effects.to_s.should == '[side-effects are [{Boy} absorbs 0/0 at 0, {Girl} absorbs 0/0 at 5]]'
    end

    it "should match with explicit leading adjective" do
      parse %q{Boy dislikes ugly-Girl;}
      @asts.size.should == 1
      side_effects = match_readings_to_existing(@asts[0], @ugly_ft.all_reading.single)
      side_effects[0].should_not be_nil
      side_effects.to_s.should == '[side-effects are [{Boy} absorbs 0/0 at 0, {ugly- Girl} absorbs 0/0 at 2]]'
    end

    it "should match with implicit leading adjective" do
      parse %q{Boy dislikes ugly Girl;}
      @asts.size.should == 1
      side_effects = match_readings_to_existing(@asts[0], @ugly_ft.all_reading.single)
      side_effects[0].should_not be_nil
      side_effects.to_s.should == '[side-effects are [{Boy} absorbs 0/0 at 0, {Girl} absorbs 1/0 at 3]]'
    end

    it "should match with local leading adjective" do
      parse %q{
        bad-Boy is going out with Girl,
        Girl likes bad-Boy; // New reading, no match expected, but must use residual adjective
      }
      @asts.size.should == 1
      side_effects = match_readings_to_existing(@asts[0], @simple_ft.all_reading.single)
      side_effects.size.should == 2
      side_effects[0].should_not be_nil
      side_effects[1].should be_nil
      pending side_effects[0].to_s
      side_effects[0].to_s.should == '[{bad- Boy} absorbs 0/0 at 0 with residual adjectives, {Girl} absorbs 0/0 at 5] with residual adjectives'
      #side_effects[1].to_s.should == ''
    end

    it "should match with explicit and local leading adjective" do
      parse %q{
        Boy dislikes nasty- ugly Girl,
        nasty- Girl likes Boy; // New reading, no match expected, but must use residual adjective
      }
      @asts.size.should == 1
      side_effects = match_readings_to_existing(@asts[0], @ugly_ft.all_reading.single)
      side_effects.size.should == 2
      pending "Matched adjectives must be removed and the role rebound before deciding whether residual adjectives have a purpose" do
        side_effects[0].should_not be_nil
        puts side_effects[0].to_s
        #side_effects.to_s.should == ''
      end
    end

    # Trailing adjectives
    it "should match with explicit trailing adjective" do
      parse %q{Boy-monster hurts Girl;}
      @asts.size.should == 1
      side_effects = match_readings_to_existing(@asts[0], @hurts_ft.all_reading.single)
      pending "Thinks trailing adjectives are always residual"
      side_effects[0].should_not be_nil
      side_effects[0].to_s.should == ''
    end

    it "should match with implicit trailing adjective" do
      parse %q{Boy monster hurts Girl;}
      @asts.size.should == 1
      side_effects = match_readings_to_existing(@asts[0], @hurts_ft.all_reading.single)
      side_effects[0].should_not be_nil
      side_effects.to_s.should == '[side-effects are [{Boy} absorbs 0/1 at 0, {Girl} absorbs 0/0 at 3]]'
    end

    it "should match with local trailing adjective" do
      parse %q{
        Boy is going out with Girl-troublemaker,
        Girl troublemaker likes Boy;
      }
      @asts.size.should == 1
      side_effects = match_readings_to_existing(@asts[0], @simple_ft.all_reading.single)
      side_effects.size.should == 2
      side_effects[0].should_not be_nil
      side_effects.to_s.should == '[side-effects are [{Boy} absorbs 0/0 at 0, {Girl -troublemaker} absorbs 0/0 at 5 with residual adjectives] with residual adjectives, nil]'
    end

    it "should match with explicit and local trailing adjective" do
      parse %q{
        Boy monster -foo hurts Girl,
          Girl likes Boy foo;
      }
      @asts.size.should == 1
      side_effects = match_readings_to_existing(@asts[0], @hurts_ft.all_reading.single)
      side_effects.size.should == 2

      pending "Matched adjectives must be removed and the role rebound before deciding whether residual adjectives have a purpose" do
        side_effects[0].should_not be_nil
        puts side_effects.to_s
        # side_effects.to_s.should == ''
      end
    end

  end
end
