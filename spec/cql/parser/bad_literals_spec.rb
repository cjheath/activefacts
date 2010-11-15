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
    "a is written as b(08);".
    should fail_to_parse /Expected (.|\n)* after a is written as b\(0$/
  end

  it "should fail to parse a hexadecimal number containing non-hexadecimal digits" do
    "a is written as b(0xDice);".
    should fail_to_parse /Expected (.|\n)* after a is written as b\(0$/
  end

  it "should fail to parse a negative number with an intervening space" do
    "a is written as b(- 1);".
    should fail_to_parse /Expected .* after a is written as b\(/
  end

  it "should fail to parse an explicit positive number with an intervening space" do
    "a is written as b(+ 1);".
    should fail_to_parse /Expected .* after a is written as b\(/
  end

  it "should fail to parse a negative octal number" do
    "a is written as b(-077);".
    should fail_to_parse /Expected .* after a is written as b\(/
  end

  it "should fail to parse a negative hexadecimal number" do
    "a is written as b(-0xFace);".
    should fail_to_parse /Expected .* after a is written as b\(/
  end

  it "should fail to parse invalid real numbers (no digits before or nonzero after the point)" do
    "a is written as b(.0);".
    should fail_to_parse /Expected .* after a is written as b\(/
  end

  it "should fail to parse invalid real numbers (no digits after or nonzero before the point)" do
    "a is written as b(0.);".
    should fail_to_parse /Expected .* after a is written as b\(/
  end

  it "should fail to parse a number with illegal whitespace before the exponent" do
    "inch converts to 1 inch; a is written as b() inch ^2 ; ".
    should fail_to_parse /Expected .* after a is written as b\(\) inch/
  end

  it "should fail to parse a number with illegal whitespace around the exponent" do
    "inch converts to 1 inch; a is written as b() inch^ 2 ; ".
    should fail_to_parse /Expected .* after a is written as b\(\) inch/
  end

  it "should fail to parse a string with an illegal octal escape" do
    "a is written as b() restricted to { '\\7a' };".
    should fail_to_parse /Expected .* a is written as b\(\) restricted to \{ '/
  end

  it "should fail to parse a string with a control character" do
    "a is written as b() restricted to { '\001' };".
    should fail_to_parse /Expected .* a is written as b\(\) restricted to \{ '/
  end

  it "should fail to parse a string with a control character" do
    "a is written as b() restricted to { '\n' };".
    should fail_to_parse /Expected .* a is written as b\(\) restricted to \{ '/
  end

  it "should fail to parse a cross-typed range" do
    "a is written as b() restricted to { 0..'A' };".
    should fail_to_parse /Expected .* after a is written as b\(\) restricted to \{ 0\.\./

    "a is written as b() restricted to { 'a'..27 };".
    should fail_to_parse /Expected .* after a is written as b\(\) restricted to \{ 'a'\.\./
  end

end
