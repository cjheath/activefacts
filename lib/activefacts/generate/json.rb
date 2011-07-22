#
#       ActiveFacts Generators.
#       Generate json output from a vocabulary, for loading into APRIMO
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'json'
require 'digest/sha1'

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
            j = {:uuid => (uuids[d] ||= uuid_from_id(d)), :name => d.name}
            "    #{j.to_json}"
          end*",\n"
        }\n  ],"

        object_types = @vocabulary.all_object_type.sort_by{|o| o.name.gsub(/ /,'')}
        puts "  object_types: [\n#{
          object_types.sort_by{|o|o.identifying_role_values.inspect}.map do |o|
            uuids[o] ||= uuid_from_id(o)
            ref_mode = nil
            if o.is_a?(ActiveFacts::Metamodel::EntityType) and
              p = o.preferred_identifier and
              (rrs = p.role_sequence.all_role_ref).size == 1 and
              (r = rrs.single.role).fact_type != o.fact_type and
              r.object_type.is_a?(ActiveFacts::Metamodel::ValueType) and
              !r.fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance)
              ref_mode = "#{r.object_type.name}"
              ref_mode.sub!(%r{#{o.name} *}, '.')
            end
            j = {
              :uuid => uuids[o],
              :name => o.name,
              :shapes => o.all_object_type_shape.map do |shape|
                x = { :diagram => uuids[shape.diagram],
                  :is_expanded => shape.is_expanded,
                  :uuid => uuid_from_id(shape),
                  :x => shape.position.x,
                  :y => shape.position.y
                }
                x[:is_expanded] = true if ref_mode && shape.is_expanded  # Don't show the reference mode
                x
              end
            }
            j[:ref_mode] = ref_mode if ref_mode
            j[:independent] = true if o.is_independent

            if o.is_a?(ActiveFacts::Metamodel::EntityType)
              # Entity Type may be objectified, and may have supertypes:
              if o.fact_type
                uuid = (uuids[o.fact_type] ||= uuid_from_id(o.fact_type))
                j[:objectifies] = uuid
                j[:implicit] = true if o.is_implied_by_objectification
              end
              if o.all_type_inheritance_as_subtype.size > 0
                j[:supertypes] = o.
                  all_type_inheritance_as_subtype.
                  sort_by{|ti| ti.provides_identification ? 0 : 1}.
                  map{|ti|
                    [ uuids[ti.supertype] ||= uuid_from_id(ti.supertype),
                      uuids[ti.supertype_role] = uuid_from_id(ti.supertype_role)
                    ]
                  }
              end
            else
              # ValueType usually has a supertype:
              if (o.supertype)
                j[:supertype] = (uuids[o.supertype] ||= uuid_from_id(o.supertype))
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
          fact_types.sort_by{|f| f.identifying_role_values.inspect}.map do |f|
            uuids[f] ||= uuid_from_id(f)
            j = {:uuid => uuids[f]}

            if f.entity_type
              j[:objectified_as] = uuids[f.entity_type]
            end

            # Emit roles
            roles = f.all_role.sort_by{|r| r.ordinal }
            j[:roles] = roles.map do |role|
              uuid = (uuids[role] ||= uuid_from_id(role))
              # REVISIT: Internal Mandatory Constraints
              # REVISIT: Place a ValueConstraint and shape
              # REVISIT: Place a RoleName shape
              {:uuid => uuid, :player => uuids[role.object_type]}
              # N.B. The object_type shape to which this role is attached is not in the meta-model
              # Attach to the closest instance on this diagram (if any)
            end

            # Emit readings. Each is a [role_order, text] pair
            j[:readings] = f.all_reading.map do |r|
              role_refs = r.role_sequence.all_role_ref_in_order
              [
                role_order(uuids, role_refs.map{|rr| rr.role}, roles),
                r.text.gsub(/\{([0-9])\}/) do |insert|
                  role_ref = role_refs[$1.to_i]
                  la = role_ref.leading_adjective
                  la = nil if la == ''
                  ta = role_ref.trailing_adjective
                  ta = nil if ta == ''
                  (la ? la+'-' : '') +
                    (la && la.index(' ') ? ' ' : '') +
                    insert +
                    (ta && ta.index(' ') ? ' ' : '') +
                    (ta ? '-'+ta : '')
                end
              ]
            end.sort_by{|(ro,text)| ro }.map do |(ro,text)|
              [ ro, text ]
            end

            # Emit shapes
            j[:shapes] = f.all_fact_type_shape.map do |shape|
              sj = {
                :diagram => uuids[shape.diagram],
                :uuid => uuid_from_id(shape),
                :x => shape.position.x,
                :y => shape.position.y
              }

              # Add the role_order, if specified
              if shape.all_role_display.size > 0
                if shape.all_role_display.size != roles.size
                  raise "Invalid RoleDisplay for #{f.default_reading}"
                end
                ro = role_order(
                  uuids,
                  shape.all_role_display.sort_by{|rd| rd.ordinal }.map{|rd| rd.role },
                  roles
                )
                sj[:role_order] = ro if ro
              end

              # REVISIT: Place the ReadingShape

              # Emit the position of the name, if objectified
              if n = shape.objectified_fact_type_name_shape
                sj[:name_shape] = {:x => n.position.x, :y => n.position.y}
              end
              sj
            end

            # Emit Internal Presence Constraints
            f.internal_presence_constraints.each do |ipc|
              uuid = (uuids[ipc] ||= uuid_from_id(ipc))

              constraint = {
                :uuid => uuid,
                :min => ipc.min_frequency,
                :max => ipc.max_frequency,
                :is_preferred => ipc.is_preferred_identifier,
                :mandatory => ipc.is_mandatory
              }

              # Get the role (or excluded role, for a UC)
              roles = ipc.role_sequence.all_role_ref_in_order.map{|r| r.role}
              if roles.size > 1 || (!ipc.is_mandatory && ipc.max_frequency == 1)
                # This can be only a uniqueness constraint. Record the missing role, if any
                role = (f.all_role.to_a - roles)[0]
                constraint[:uniqueExcept] = uuids[role]
              else
                # An internal mandatory or frequency constraint applies to only one role.
                # If it's also unique (max == 1), that applies on the counterpart role.
                # You can also have a mandatory frequency constraint, but that applies on this role.
                constraint[:role] = uuids[roles[0]]
              end
              (j[:constraints] ||= []) << constraint
            end

            # Add ring constraints
            f.all_role_in_order.
              map{|r| r.all_ring_constraint.to_a+r.all_ring_constraint_as_other_role.to_a }.
              flatten.uniq.each do |ring|
                (j[:constraints] ||= []) << {
                    :uuid => (uuids[ring] ||= uuid_from_id(ring)),
                    :shapes => ring.all_constraint_shape.map do |shape|
                      { :diagram => uuids[shape.diagram],
                        :uuid => uuid_from_id(shape),
                        :x => shape.position.x,
                        :y => shape.position.y
                      }
                    end,
                    :ringKind => ring.ring_type,
                    :roles => [uuids[ring.role], uuids[ring.other_role]]
                    # REVISIT: Deontic, enforcement
                  }
              end

            # REVISIT: RotationSetting

            "    #{j.to_json}"
          end*",\n"
        }\n  ],"

        constraints = @vocabulary.constellation.
          Constraint.values
        puts "  constraints: [\n#{
          constraints.sort_by{|c|c.identifying_role_values.inspect}.select{|c| !uuids[c]}.map do |c|
            uuid = uuids[c] ||= uuid_from_id(c)
            j = {
              :uuid => uuid,
              :type => c.class.basename,
              :shapes => c.all_constraint_shape.map do |shape|
                { :diagram => uuids[shape.diagram],
                  :uuid => uuid_from_id(shape),
                  :x => shape.position.x,
                  :y => shape.position.y
                }
              end
            }

            if (c.enforcement)
              # REVISIT: Deontic constraint
            end
            if (c.all_context_note.size > 0)
              # REVISIT: Context Notes
            end

            case c
            when ActiveFacts::Metamodel::PresenceConstraint
              j[:min_frequency] = c.min_frequency
              j[:max_frequency] = c.max_frequency
              j[:is_mandatory] = c.is_mandatory
              j[:is_preferred_identifier] = c.is_preferred_identifier
              rss = [c.role_sequence.all_role_ref_in_order.map(&:role)]

              # Ignore internal presence constraints on TypeInheritance fact types
              next nil if !c.role_sequence.all_role_ref.
                detect{|rr|
                  !rr.role.fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance)
                }

            when ActiveFacts::Metamodel::RingConstraint
              next nil  # These are emitted with the corresponding fact type

            when ActiveFacts::Metamodel::SetComparisonConstraint
              rss = c.
                all_set_comparison_roles.sort_by{|scr| scr.ordinal}.
                map{|scr| scr.role_sequence.all_role_ref_in_order.map(&:role) }
              if (ActiveFacts::Metamodel::SetExclusionConstraint === c)
                j[:is_mandatory] = c.is_mandatory
              end

            when ActiveFacts::Metamodel::SubsetConstraint
              rss = [c.subset_role_sequence, c.superset_role_sequence].
                map{|rs| rs.all_role_ref_in_order.map(&:role) }

            when ActiveFacts::Metamodel::ValueConstraint
              next nil  # REVISIT: Should have been handled elsewhere
              if (c.role)
                # Should have been handled as role.role_value_constraint
              elsif (c.value_type)
                # Should have been handled as object_type.value_constraint
              end
              j[:allowed_ranges] = c.all_allowed_range.map{|ar|
                [ ar.value_range.minimum_bound, ar.value_range.maximum_bound ].
                  map{|b| [b.value.literal, b.value.unit.name, b.is_inclusive] }
              }

            else
              raise "REVISIT: Constraint type not yet dumped to JSON"
            end

            # rss contains the constrained role sequences; map to uuids
            j[:role_sequences] = rss.map{|rs|
              rs.map do |role|
                uuids[role]
              end
            }

            "    #{j.to_json}"
          end.compact*",\n"
        }\n  ]"

        puts "}"
      end

      def role_order(uuids, roles, order)
        if (roles.size > 9)
          roles.map{|r| uuids[r] }
        else
          roles.map{|r| order.index(r).to_s }*''
        end
      end

      def uuid_from_id o
        irvs = o.identifying_role_values.inspect
        d = Digest::SHA1.digest irvs
        # $stderr.puts "#{o.class.basename}: #{irvs}"
        d[0,4].unpack("H8")[0]+'-'+
          d[4,2].unpack("H4")[0]+'-'+
          d[6,2].unpack("H4")[0]+'-'+
          d[8,2].unpack("H4")[0]+'-'+
          d[10,6].unpack("H6")[0]
      end

    end
  end
end

