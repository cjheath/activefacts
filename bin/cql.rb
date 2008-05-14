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
      p result.value
    rescue => e
      puts e
      puts "\t"+e.backtrace*"\n\t"
    end
    statement = ''
  end
end
puts

