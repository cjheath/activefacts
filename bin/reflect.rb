#! /usr/bin/ruby
#
# $Id$
#
#	Test Program to reverse engineer a schema from a database.
#	Connections to the database are made using ActiveRecord.
#

require "rubygems"
require "pp"
require "active_record"
require "drysql"
require "activefacts"
require "activefacts/reflection"

include ActiveFacts

# Database connection parameters:
adapter = "sqlserver"
host = "localhost"
mode = "ODBC"
database = dsn = nil
user = nil
password = nil
logfile = nil

ARGV.each{|arg|
    all, op, modname, params =
	    /\A--([a-z]*)(?:-([^=]*))?(?:=(.*))?/.match(arg)[0..-1]
    params = params ? params.split(/,/) : []
    p0 = params[0]
    case op
    when "adapter";		adapter = p0
    when "host";		host = p0
    when "mode";		mode = p0
    when "database", "dsn";	dsn = database = p0
    when "user";		user = p0
    when "password";	    	password = p0
    when "log";			logfile = p0 || "-"
    else
	throw "Unrecognised parameter #{arg}"
    end
}

#%w{adapter host database dsn user password socket}.each{|w|
#    begin
#	puts "#{w}: '#{eval w}'"
#    rescue
#    end
#}

ActiveRecord::Base.pluralize_table_names = false
ActiveRecord::Base.primary_key_prefix_type = :table_name
reflector = ActiveFacts::Reflector.new(
	{:adapter => adapter,
	:host => host,
	:mode => mode,
	:database => database,
	:dsn => dsn,
	:username => user,
	:password => password,
	:socket => "/var/run/mysqld/mysqld.sock"},
	logfile ? ("-" == logfile ? $> : File.new(logfile, "w")) : nil
    )

model = reflector.load_schema

def show_roles(o, f)
    num_fact_roles = f.roles.size
    o_fact_roles = f.roles.select{|r| r.object_type == o}
    nofr = o_fact_roles.size
    puts "\t\t#{f.name}" +
	(nofr > 1 ? ", #{o_fact_roles.size} of #{num_fact_roles} roles:" : "") +
	" (#{o_fact_roles.map(&:to_s)*", "})"
end

puts "All Entity Types:"
model.object_types.sort_by{|o| o.name}.each{|o|
	next if !(EntityType === o)	# includes NestedTypes
	puts "\t"+o.to_s+" and plays #{o.fact_types.size == 0 ? "no roles" : "roles in:"}"
	o.fact_types.each{|f| show_roles(o, f) }
    }

puts "\n\nAll Value Types:"
model.object_types.sort_by{|o| o.name}.each{|o|
	next if EntityType === o
	puts "\t"+o.to_s+" and plays #{o.fact_types.size == 0 ? "no roles" : "roles in:"}"
	o.fact_types.each{|f| show_roles(o, f) }
    }

puts "\n\nAll Fact Types:"
model.fact_types.each{|f|
	puts "\t"+f.to_s
	r = f.readings
#	puts r.to_yaml
	r.each{|r|
	    puts "\t\t"+r.to_s
	}
    }

puts "\n\nAll Constraints:"
model.constraints.each{|c|
	# Skip presence constraints on value types:
    #    next if ActiveFacts::PresenceConstraint === c &&
    #	    ActiveFacts::ValueType === c.object_type
	puts "\t"+c.to_s
    }
