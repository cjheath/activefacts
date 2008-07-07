#
# Interactive CQL command-line.
# Copyright (c) 2007 Clifford Heath. Read the LICENSE file.
#

require 'activefacts'
require 'activefacts/cql/parser'
require 'readline'

parser = ActiveFacts::CQLParser.new
statement = ""
while line = Readline::readline(statement == "" ? "CQL? " : "CQL+ ", [])
  # If after stripping string literals the line contains a ';', it's the last line of the command:
  statement << line
  if line.gsub(/(['"])([^\1\\]|\\.)*\1/,'') =~ /;/
    begin
      parser.root = :definition
      result = parser.parse(statement)
      if result
        #p result.value
        p parser.definition(result)
      else
        p parser.failure_reason
      end
    rescue => e
      puts e
      puts "\t"+e.backtrace*"\n\t"
    end
    statement = ''
  end
end
puts

