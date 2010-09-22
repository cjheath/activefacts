#
# ActiveFacts tests: Parse all CQL files and check the generated DataMapper models
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'spec/spec_helper'
require 'stringio'
require 'activefacts/vocabulary'
require 'activefacts/support'
require 'activefacts/input/cql'
require 'activefacts/generate/dm'
require 'dm-core'
require 'dm-core/spec/lib/spec_helper'

describe "CQL Loader with DataMapper output" do
  cql_failures = {      # These CQL files can't be compiled
  }
  mapping_failures = {  # These models can't be mapped to DM
    'OrienteeringER' => 'Invalid CQL results in unmappable model',
    'Insurance' => 'Cannot handle models that contain classes like Vehicle Incident with external supertypes (Incident)',
    'MetamodelNext' => 'Cannot handle models that contain classes like Constraint with external supertypes (Concept)',
    'MultiInheritance' => 'Cannot handle models that contain classes like Australian Employee with external supertypes (Australian)',
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

      # Build and save the actual file:
      dm_text = ''
      lambda do
        begin
          dm_text = dm(vocabulary)
          File.open(actual_file, "w") { |f| f.write dm_text }
        rescue
          raise unless mapping_failures[base]
        end
      end.should_not raise_error

      if m = mapping_failures[base]
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
