#
# Read an ORM2 Vocabulary from a NORMA, CQL or other file
#
# Copyright (c) 2007 Clifford Heath. Read the LICENSE file.
#
$:.unshift File.dirname(File.expand_path(__FILE__))+"/../lib"

require 'rubygems'
require 'activefacts'
require 'activefacts/vocabulary'
require 'activefacts/support'
include ActiveFacts

arg = ARGV.shift

# Load the required generator, or the default "text" generator:
generator = "text"
if arg =~ /^--(.*)/
  generator = $1
  arg = ARGV.shift
end
output_handler = "activefacts/generate/#{generator.downcase}"
require output_handler
output_class = generator.upcase
output_klass = ActiveFacts::Generate.const_get(output_class.to_sym)
raise "Expected #{output_handler} to define #{output_class}" unless output_klass

# Load the file type input method
extension = arg.sub(/\A.*\./,'').downcase
input_handler = "activefacts/input/#{extension}"
require input_handler
input_class = extension.upcase
input_klass = ActiveFacts::Input.const_get(input_class.to_sym)
raise "Expected #{input_handler} to define #{input_class}" unless input_klass

# Read the input file:
begin
  vocabulary = input_klass.readfile(arg)
rescue => e
  puts "#{e}:\n\t#{e.backtrace*"\n\t"}"
end

# Generate the output:
output_klass.new(vocabulary).generate if vocabulary
