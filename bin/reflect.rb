#! /usr/bin/ruby
#
#	Test Program to reverse engineer a schema from a database.
#	Connections to the database are made using ActiveRecord.
#
# Copyright (c) 2007 Clifford Heath. Read the LICENSE file.
#

require "rubygems"
require "pp"
require "active_record"
require "drysql"
require "activefacts"
require "activefacts/reflection"
require 'activefacts/dump'

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

model.dump
