#
# ActiveFacts tests: Parse all CQL files and check the generated DataMapper models
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
# From IRC, on how to extract the SQL that DM creates for a set of models:
#
# I can tell you that ::DataObjects::Connection#log gets you the SQL
# after its run (not exactly what you asked for, but a place to start
# looking).
# 
# your choices are intercepting
# ::DataMapper::Adapters::DataObjectsAdapter#{select,execute} for
# direct SQL calls, or at a lower level,
# ::DataObjects::Connection#create_command for all SQL.
# 
# one trick I've been using is to selectively intercept the latter
# and not let it run (no-op it but log/inspect it), which can obviously
# screw up anything else back up the call stack but at least gives
# you the opportunity to catch it if you want.
# 
# #create_command returns Command, which is subsequently called with
# #execute_reader(bind_values) or #execute_non_query(bind_values),
# so if the final query is what you're after, then you'll have to
# hook those both instead.

require 'spec_helper'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/cql'
require 'activefacts/generate/dm'
require 'dm-core'
require 'dm-core/spec/lib/spec_helper'

#def SecureRandom.uuid
#  @@counter ||= 99999999999
#  h = "%032X" % @@counter
#  @@counter -= 1
#  h.
#    sub(
#      @@format_pattern ||= /(........)(....)(....)(....)(............)/,
#      @@format_string ||= '\1-\2-\3-\4-\5'
#    )
#end

describe "CQL Loader with DataMapper output" do
  cql_failures = {      # These CQL files can't be compiled
  }
  mapping_failures = {  # These models can't be mapped to DM
    'OrienteeringER' => 'Invalid CQL results in unmappable model',
    'Insurance' => 'Cannot handle models that contain classes like Vehicle Incident with external supertypes (Incident)',
    'MultiInheritance' => 'Cannot handle models that contain classes like Australian Employee with external supertypes (Australian)',
    'Metamodel' => 'cannot be used as a property name since it collides with an existing method',
    'MetamodelNext' => 'Cannot map classes like Constraint with roles inherited from external supertypes (Concept)',
    'SeparateSubtype' => 'Cannot handle models that contain classes like Vehicle Incident with external supertypes (Incident)',
    'ServiceDirector' => 'Cannot handle models that contain classes like Client with external supertypes (Company)',
  }
  dm_failures = {       # These mapped models don't work in DM
    'RedundantDependency' => 'Cannot find the child_model Addres for StateOrProvince in address while finalizing StateOrProvince.address',
    'Supervision' => 'Inflexion failure: Cannot find the parent_model Ceo for Company in ceo while finalizing Company.ceo',
  }

  # Generate and return the DataMapper models for the given vocabulary
  def dm(vocabulary)
    output = StringIO.new
    @dumper = ActiveFacts::Generate::DM.new(vocabulary.constellation)
    @dumper.generate(output)
    output.rewind
    output.read
  end

  pattern = ENV["AFTESTS"] || "*"
  Dir["examples/CQL/#{pattern}.cql"].each do |cql_file|
    expected_file = cql_file.sub(%r{/CQL/(.*).cql\Z}, '/datamapper/\1.dm.rb')
    actual_file = cql_file.sub(%r{examples/CQL/(.*).cql\Z}, 'spec/actual/\1.dm.rb')
    base = File.basename(cql_file, ".cql")

    next unless ENV["AFTESTS"] || File.exists?(expected_file)

    it "should load #{cql_file} and dump DataMapper models matching #{expected_file}" do
      vocabulary = nil
      broken = cql_failures[base]
      if broken
        pending(broken) {
          vocabulary = ActiveFacts::Input::CQL.readfile(cql_file)
        }
      else
        vocabulary = ActiveFacts::Input::CQL.readfile(cql_file)
      end
      vocabulary.finalise

      # Build and save the actual file:
      dm_text = ''
      lambda do
        begin
          dm_text = dm(vocabulary)
	  Dir.mkdir "spec/actual" rescue nil
          File.open(actual_file, "w") { |f| f.write dm_text }
        rescue
          raise unless mapping_failures[base]
        end
      end.should_not raise_error

      if m = mapping_failures[base]
        File.delete(actual_file) rescue nil
        pending m
      end

      lambda do
        begin
          eval dm_text
          DataMapper.finalize
        rescue
          raise unless dm_failures[base]
        ensure
          DataMapper::Spec.cleanup_models
        end
      end.should_not raise_error
      if m = dm_failures[base]
        File.delete(actual_file) rescue nil
        pending m
      end

      pending("expected output file #{expected_file} not found") unless File.exists? expected_file

      # Compare with the expected file:
      expected_text = File.open(expected_file) {|f| f.read }
      dm_text.should_not differ_from(expected_text)
      File.delete(actual_file)  # It succeeded, we don't need the file.
    end
  end
end
