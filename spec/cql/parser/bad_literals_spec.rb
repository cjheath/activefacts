#
# ActiveFacts tests: Test the CQL parser by looking at its parse trees.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'activefacts/cql'
require 'activefacts/support'
require 'activefacts/api/support'
require 'spec_helper'
require 'helpers/test_parser'

describe "Parsing Invalid Numbers and Strings" do
  it "should fail to parse an octal number containing non-octal digits" do
    "aa is written as b(08);".
    should fail_to_parse /Expected (.|\n)* at .* after aa is written as b\(0$/
  end

  it "should fail to parse a hexadecimal number containing non-hexadecimal digits" do
    "aa is written as b(0xDice);".
    should fail_to_parse /Expected \[0-9A-Fa-f\] at .* after aa is written as b\(0xD$/
  end

  it "should fail to parse a negative number with an intervening space" do
    "aa is written as b(- 1);".
    should fail_to_parse /Expected .* after aa is written as b\(/
  end

  it "should fail to parse an explicit positive number with an intervening space" do
    "aa is written as b(+ 1);".
    should fail_to_parse /Expected .* after aa is written as b\(/
  end

  it "should fail to parse a negative octal number" do
    "aa is written as b(-077);".
    should fail_to_parse /Expected .* after aa is written as b\(/
  end

  it "should fail to parse a negative hexadecimal number" do
    "aa is written as b(-0xFace);".
    should fail_to_parse /Expected .* after aa is written as b\(/
  end

  it "should fail to parse invalid real numbers (no digits before or nonzero after the point)" do
    "aa is written as b(.0);".
    should fail_to_parse /Expected .* after aa is written as b\(/
  end

  it "should fail to parse invalid real numbers (no digits after or nonzero before the point)" do
    "aa is written as b(0.);".
    should fail_to_parse /Expected .* after aa is written as b\(/
  end

  it "should fail to parse a number with illegal whitespace before the exponent" do
    "inch converts to 1 inch; aa is written as b() inch ^2 ; ".
    should fail_to_parse /Expected .* after aa is written as b\(\) inch/
  end

  it "should fail to parse a number with illegal whitespace around the exponent" do
    "inch converts to 1 inch; aa is written as b() inch^ 2 ; ".
    should fail_to_parse /Expected .* after aa is written as b\(\) inch/
  end

  it "should fail to parse a string with an illegal octal escape" do
    "aa is written as b() restricted to { '\\7a' };".
    should fail_to_parse /Expected .* aa is written as b\(\) restricted to \{ '/
  end

  it "should fail to parse a string with a control character" do
    "aa is written as b() restricted to { '\001' };".
    should fail_to_parse /Expected .* aa is written as b\(\) restricted to \{ '/
  end

  it "should fail to parse a string with a control character" do
    "aa is written as b() restricted to { '\n' };".
    should fail_to_parse /Expected .* aa is written as b\(\) restricted to \{ '/
  end

  it "should fail to parse a cross-typed range" do
    "aa is written as b() restricted to { 0..'A' };".
    should fail_to_parse /Expected .* after aa is written as b\(\) restricted to \{ 0\.\./

    "aa is written as b() restricted to { 'a'..27 };".
    should fail_to_parse /Expected .* after aa is written as b\(\) restricted to \{ 'a'\.\./
  end

end
