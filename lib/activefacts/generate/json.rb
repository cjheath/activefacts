#
#       ActiveFacts Generators.
#       Generate json output from a vocabulary, for loading into APRIMO
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'json'
require 'sysuuid'

module ActiveFacts
  module Generate
    # Generate json output from a vocabulary, for loading into APRIMO.
    # Invoke as
    #   afgen --json <file>.cql=diagrams
    class JSON
    private
      def initialize(vocabulary)
        @vocabulary = vocabulary
        @vocabulary = @vocabulary.Vocabulary.values[0] if ActiveFacts::API::Constellation === @vocabulary
      end

      def puts(*a)
        @out.puts *a
      end

    public
      def generate(out = $>)
        @out = out
        uuids = {}

        puts "{ model: '#{@vocabulary.name}',\n" +
        "diagrams: [\n#{
          @vocabulary.all_diagram.sort_by{|o| o.name.gsub(/ /,'')}.map do |d|
            uuid = uuids[d] ||= SysUUID.new.sysuuid
            j = {:uuid=>uuid, :name=>d.name}
            "    #{j.to_json}"
          end*",\n"
        }\n  ],"

        object_types = @vocabulary.all_object_type.sort_by{|o| o.name.gsub(/ /,'')}
        puts "  object_types: [\n#{
          object_types.map do |o|
            uuids[o] ||= SysUUID.new.sysuuid
            j = {
              :uuid=>uuids[o],
              :name=>o.name,
              :shapes => o.all_object_type_shape.map do |shape|
                {:diagram=>uuids[shape.diagram], :x=>shape.position.x, :y=>shape.position.y}
              end
            }
            if o.is_a?(ActiveFacts::Metamodel::EntityType)
              # Entity Type may be objectified, and may have supertypes:
              if o.fact_type
                uuid = (uuids[o.fact_type] ||= SysUUID.new.sysuuid)
                j[:objectifies] = uuid
              end
              if o.all_type_inheritance_as_subtype.size > 0
                j[:supertypes] = o.
                  all_type_inheritance_as_subtype.
                  sort_by{|ti| ti.provides_identification ? 0 : 1}.
                  map{|ti| uuids[ti.supertype] ||= SysUUID.new.sysuuid }
              end
            else
              # ValueType usually has a supertype:
              if (o.supertype)
                j[:supertype] = (uuids[o.supertype] ||= SysUUID.new.sysuuid)
              end
            end
            # REVISIT: Place a ValueConstraint and shape
            "    #{j.to_json}"
          end*",\n"
        }\n  ],"

        fact_types = @vocabulary.constellation.
          FactType.values.
          reject{|ft|
            ActiveFacts::Metamodel::ImplicitFactType === ft || ActiveFacts::Metamodel::TypeInheritance === ft
          }
        puts "  fact_types: [\n#{
          fact_types.map do |f|
            uuids[f] ||= SysUUID.new.sysuuid
            j = {:uuid=>uuids[f]}
            # REVISIT: Place the ReadingShape
            j[:objectified_as] = uuids[f.entity_type] if f.entity_type
            j[:roles] = f.all_role.map do |role|
              uuid = (uuids[role] ||= SysUUID.new.sysuuid)
              # REVISIT: Internal Mandatory Constraints
              # REVISIT: Place a ValueConstraint and shape
              # REVISIT: Place a RoleName shape
              {:uuid=>uuid, :player=>uuids[role.object_type]}
            end
            j[:shapes] = f.all_fact_type_shape.map do |shape|
              sj = {
                :diagram=>uuids[shape.diagram],
                :x=>shape.position.x, :y=>shape.position.y
              }
              if shape.all_role_display.size > 0
                sj[:role_order] = shape.all_role_display.sort_by{|rd| rd.ordinal }.map{|rd| uuids[rd.role] }
              end
              if n = shape.objectified_fact_type_name_shape
                sj[:name_shape] = {:x=>n.position.x, :y=>n.position.y}
              end
              sj
            end
            f.internal_presence_constraints.each do |ipc|
              uuid = (uuids[ipc] ||= SysUUID.new.sysuuid)
              (j[:constraints] ||= []) <<
                {
                  :uuid => uuid,
                  :min => ipc.min_frequency,
                  :max => ipc.max_frequency,
                  :is_preferred => ipc.is_preferred_identifier,
                  :mandatory => ipc.is_mandatory
                }
            end
            # REVISIT: RingConstraints
            # REVISIT: RotationSetting
            "    #{j.to_json}"
          end*",\n"
        }\n  ],"

        constraints = @vocabulary.constellation.
          Constraint.values
        puts "  constraints: [\n#{
          constraints.select{|c| !uuids[c]}.map do |c|
            uuid = uuids[c] ||= SysUUID.new.sysuuid
            j = {
              :uuid => uuid,
              :type => c.class.basename,
              :shapes => c.all_constraint_shape.map do |shape|
                { :diagram=>uuids[shape.diagram], :x=>shape.position.x, :y=>shape.position.y }
              end
            }
            # REVISIT: constraint type
            # REVISIT: constrained role sequences
            "    #{j.to_json}"
          end*",\n"
        }\n  ]"

        puts "}"
      end
    end
  end
end

