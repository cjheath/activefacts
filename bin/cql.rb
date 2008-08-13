#
# Interactive CQL command-line.
# Copyright (c) 2007 Clifford Heath. Read the LICENSE file.
#

require 'activefacts'
require 'activefacts/cql/parser'
require 'readline'

parser = ActiveFacts::CQLParser.new
parser.root = :definition
statement = ""
while line = Readline::readline(statement == "" ? "CQL? " : "CQL+ ", [])
  statement << line
  if line =~ %r{\A/}
    # meta-command, modify the parser call
    case (words = line.split).shift
    when "/root"
      parser.root = words[0] && words[0].to_sym || :definition
      puts "ok"
    else
      puts "Unknown metacommand #{line}, did you mean /root <rule>?"
    end
    statement = ''
  elsif parser.root != :definition or
      line.gsub(/(['"])([^\1\\]|\\.)*\1/,'') =~ /;/
    # After stripping string literals the line contains a ';', it's the last line of the command:
    begin
      result = parser.parse(statement)
      if result
        p result.value rescue p result  # In case the root is changed and there's no value()
        #p parser.definition(result)
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

