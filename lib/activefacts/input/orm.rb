#
# Read a NORMA file into an ActiveFacts vocabulary
#
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
# This code uses variables prefixed with x_ when they refer to Rexml nodes.
# Every node having an id="..." is indexed in @x_by_id[] hash before processing.
# As we build ActiveFacts objects to match, we index those in @by_id[].
# Both these hashes may be looked up by any of the ref="..." values in the file.
#
require 'rexml/document'
require 'activefacts/vocabulary'

module ActiveFacts
  module Input
    class ORM
      def self.readfile(filename)
        File.open(filename) {|file|
          self.read(file, filename)
        }
      end

      def self.read(file, filename = "stdin")
        ORM.new(file, filename).read
      end 

      def initialize(file, filename = "stdin")
        @file = file
        @filename = filename
      end

      def read
        begin
          doc = REXML::Document.new(@file)
        rescue => e
          puts "Failed to parse XML in #{@filename}: #{e.inspect}"
        end

        # Find the Vocabulary and do some setup:
        root = doc.elements[1]
        if root.expanded_name == "ormRoot:ORM2"
          x_models = root.elements.to_a("orm:ORMModel")
          throw "No vocabulary found" unless x_models.size == 1
          @x_model = x_models[0]
        elsif root.name == "ORMModel"
          @x_model = doc.elements[1]
        else
          pp root
          throw "NORMA vocabulary not found in file"
        end

        read_vocabulary
        @vocabulary
      end

      def read_vocabulary
        @constellation = Constellation.new(ActiveFacts::Metamodel)
        @vocabulary = @constellation.Vocabulary(@x_model.attributes['Name'], nil)

        # Find all elements having an "id" attribute and index them
        x_identified = @x_model.elements.to_a("//*[@id]")
        @x_by_id = x_identified.inject({}){|h, x|
          id = x.attributes['id']
          h[id] = x
          h
        }

        # Everything we build will be indexed here:
        @by_id = {}

        read_entity_types
        read_value_types
        read_fact_types
        read_nested_types
        read_subtypes
        read_roles
        read_constraints
        # REVISIT: Skip instance data for now:
        #read_instances
      end

      def read_entity_types
        # get and process all the entity types:
        entity_types = []
        x_entity_types = @x_model.elements.to_a("orm:Objects/orm:EntityType")
        x_entity_types.each{|x|
          id = x.attributes['id']
          name = x.attributes['Name'] || ""
          name.gsub!(/\s/,'')
          name = nil if name.size == 0
          # puts "EntityType #{name} is #{id}"
          entity_types <<
            @by_id[id] = @constellation.EntityType(name, @vocabulary)
  #       x_pref = x.elements.to_a("orm:PreferredIdentifier")[0]
  #       if x_pref
  #         pi_id = x_pref.attributes['ref']
  #         @pref_id_for[pi_id] = x
  #       end
        }
      end

      def read_value_types
        # Now the value types:
        value_types = []
        x_value_types = @x_model.elements.to_a("orm:Objects/orm:ValueType")
        #pp x_value_types
        x_value_types.each{|x|
          id = x.attributes['id']
          name = x.attributes['Name'] || ""
          name.gsub!(/\s/,'')
          name = nil if name.size == 0

          cdt = x.elements.to_a('orm:ConceptualDataType')[0]
          scale = cdt.attributes['Scale']
          scale = scale != "" && scale.to_i
          length = cdt.attributes['Length']
          length = length != "" && length.to_i
          base_type = @x_by_id[cdt.attributes['ref']]
          type_name = "#{base_type.name}"
          type_name.sub!(/^orm:/,'')
          type_name.sub!(/DataType\Z/,'')
          type_name.sub!(/Numeric\Z/,'')
          type_name.sub!(/Temporal\Z/,'')
          length = 32 if type_name =~ /Integer\Z/ && length.to_i == 0 # Set default integer length
          data_type = type_name != name ? @constellation.ValueType(type_name, @vocabulary) : nil

          # puts "ValueType #{name} is #{id}"
          value_types <<
            @by_id[id] =
            vt = @constellation.ValueType(name, @vocabulary)
          vt.supertype = data_type
          vt.length = length if length
          vt.scale = scale if scale

          x_ranges = x.elements.to_a("orm:ValueRestriction/orm:ValueConstraint/orm:ValueRanges/orm:ValueRange")
          next if x_ranges.size == 0
          vt.value_restriction = @constellation.ValueRestriction(:new)
          x_ranges.each{|x_range|
            v_range = value_range(x_range)
            ar = @constellation.AllowedRange(v_range, vt.value_restriction)
          }
        }
      end

      def value_range(x_range)
        min = x_range.attributes['MinValue']
        max = x_range.attributes['MaxValue']
        q = "'"
        min = min =~ /[^0-9\.]/ ? q+min+q : min.to_i
        max = max =~ /[^0-9\.]/ ? q+max+q : max.to_i
        # ValueRange takes a minimum and/or a maximum Bound, each takes value and whether inclusive
        @constellation.ValueRange(
            min ? [min.to_s, true] : nil,
            max ? [max.to_s, true] : nil
          )
      end

      def read_fact_types
        # Handle the fact types:
        facts = []
        @x_facts = @x_model.elements.to_a("orm:Facts/orm:Fact")
        @x_facts.each{|x|
          id = x.attributes['id']
          name = x.attributes['Name'] || x.attributes['_Name']
          name = "<unnamed>" if !name
          name.gsub!(/\s/,'')
          name = "" if !name || name.size == 0
          # Note that the new metamodel doesn't have a name for a facttype unless it's objectified

          # puts "FactType #{name || id}"
          facts << @by_id[id] = fact_type = @constellation.FactType(:new)
        }
      end

      def read_subtypes
        # Handle the subtype fact types:
        facts = []
        @x_subtypes = @x_model.elements.to_a("orm:Facts/orm:SubtypeFact")
        @x_subtypes.each{|x|
          id = x.attributes['id']
          name = x.attributes['Name'] || x.attributes['_Name'] || ''
          name.gsub!(/\s/,'')
          name = nil if name.size == 0
          # puts "FactType #{name || id}"

          x_subtype_role = x.elements['orm:FactRoles/orm:SubtypeMetaRole']
          subtype_role_id = x_subtype_role.attributes['id']
          subtype_id = x_subtype_role.elements['orm:RolePlayer'].attributes['ref']
          subtype = @by_id[subtype_id]

          x_supertype_role = x.elements['orm:FactRoles/orm:SupertypeMetaRole']
          supertype_role_id = x_supertype_role.attributes['id']
          supertype_id = x_supertype_role.elements['orm:RolePlayer'].attributes['ref']
          supertype = @by_id[supertype_id]

          throw "For Subtype fact #{name}, the supertype #{supertype_id} was not found" if !supertype
          throw "For Subtype fact #{name}, the subtype #{subtype_id} was not found" if !subtype
          # $stderr.puts "#{subtype.name} is a subtype of #{supertype.name}"

          inheritance_fact = @constellation.TypeInheritance(subtype, supertype)
          inheritance_fact.fact_type_id = :new
          if x.attributes["IsPrimary"] == "true" or           # Old way
            x.attributes["PreferredIdentificationPath"] == "true"   # Newer
          # $stderr.puts "#{supertype.name} is primary supertype of #{subtype.name}"
          inheritance_fact.provides_identification = true
          end
          facts << @by_id[id] = inheritance_fact

          # Create the new Roles so we can find constraints on them:
          subtype_role = @by_id[subtype_role_id] = @constellation.Role(:new)
          subtype_role.concept = subtype
          subtype_role.fact_type = inheritance_fact

          supertype_role = @by_id[supertype_role_id] = @constellation.Role(:new)
          supertype_role.concept = supertype
          supertype_role.fact_type = inheritance_fact
        }
      end

      def read_nested_types
        # Process NestedTypes, but ignore ones having a NestedPredicate with IsImplied="true"
        # We'll ignore the fact roles (and constraints) that implied objectifications have.
        # This happens for all ternaries and higher order facts
        nested_types = []
        x_nested_types = @x_model.elements.to_a("orm:Objects/orm:ObjectifiedType")
        x_nested_types.each{|x|
          id = x.attributes['id']
          name = x.attributes['Name'] || ""
          name.gsub!(/\s/,'')
          name = nil if name.size == 0

          x_fact_type = x.elements.to_a('orm:NestedPredicate')[0]
          is_implied = x_fact_type.attributes['IsImplied'] == "true"

          fact_id = x_fact_type.attributes['ref']
          fact_type = @by_id[fact_id]
          throw "Nested fact #{fact_id} not found" if !fact_type

          #if is_implied
          #    puts "Implied type #{name} (#{id}) nests #{fact_type ? fact_type.fact_type_id : "unknown"}"
          #    @by_id[id] = fact_type
          #else
          begin
            #puts "NestedType #{name} is #{id}, nests #{fact_type.fact_type_id}"
            nested_types <<
              @by_id[id] =
              nested_type = @constellation.EntityType(name, @vocabulary)
            nested_type.fact_type = fact_type
          end
        }
      end

      def read_roles
        @x_facts.each{|x|
          id = x.attributes['id']
          fact_type = @by_id[id]
          fact_name = x.attributes['Name'] || x.attributes['_Name'] || ''
          fact_name.gsub!(/\s/,'')
          fact_name = nil if fact_name == ''

          x_fact_roles = x.elements.to_a('orm:FactRoles/*')
          x_reading_orders = x.elements.to_a('orm:ReadingOrders/*')

          # Deal with FactRoles (Roles):
          x_fact_roles.each{|x|
            name = x.attributes['Name'] || ""
            name.gsub!(/\s/,'')
            name = nil if name.size == 0

            # _IsMandatory = x.attributes['_IsMandatory']
            # _Multiplicity = x.attributes['_Multiplicity]
            id = x.attributes['id']
            ref = x.elements[1].attributes['ref']

            # Find the concept that plays the role:
            concept = @by_id[ref]
            throw "RolePlayer for #{name||ref} was not found" if !concept

            # Skip implicit roles added by NORMA to make unaries into binaries.
            # This would make constraints over the deleted roles impossible,
            # so as a SPECIAL CASE we index the unary role by the id of the
            # implicit role. That means care is needed when handling unary FTs.
            if (ox = @x_by_id[ref]) && ox.attributes['IsImplicitBooleanValue']
              x_other_role = x.parent.elements.to_a('orm:Role').reject{|x_role|
                  x_role == x
                }[0]
              other_role_id = x_other_role.attributes["id"]
              other_role = @by_id[other_role_id]
              # puts "Indexing unary FT role #{other_role_id} by implicit boolean role #{id}"
              @by_id[id] = other_role

              # The role name of the ignored role is the one that applies:
              role_name = x.attributes['Name']
              other_role.role_name = role_name if role_name && role_name != ''

              concept.delete    # Delete our object for the implicit boolean ValueType
              @by_id.delete(ref)    # and de-index it from our list
              next
            end

            #puts "#{@vocabulary}, Name=#{x.attributes['Name']}, concept=#{concept}"
            throw "Role is played by #{concept.class} not Concept" if !(@constellation.vocabulary.concept(:Concept) === concept)

            name = x.attributes['Name'] || ''
            name.gsub!(/\s/,'')
            name = nil if name.size == 0
            #puts "Creating role #{name} of #{fact_type.fact_type_id} played by #{concept.name}"

            role = @by_id[id] = @constellation.Role(:new)
            role.concept = concept
            role.fact_type = fact_type
            role.role_name = name if name
            # puts "Fact #{fact_name} (id #{fact_type.fact_type_id.object_id}) role #{x.attributes['Name']} is played by #{concept.name}, role is #{role.object_id}"

            x_vr = x.elements.to_a("orm:ValueRestriction")
            x_vr.each{|vr|
              x_ranges = vr.elements.to_a("orm:RoleValueConstraint/orm:ValueRanges/orm:ValueRange")
              next if x_ranges.size == 0
              role.value_restriction = @constellation.ValueRestriction(:new)
              x_ranges.each{|x_range|
                v_range = value_range(x_range)
                ar = @constellation.AllowedRange(v_range, role.value_restriction)
              }
            }

            # puts "Adding Role #{role.name} to #{fact_type.name}"
            #fact_type.add_role(role)
            # puts "\tRole #{role} is #{id}"
          }

          # Deal with Readings:
          x_reading_orders.each{|x|
            x_role_sequence = x.elements.to_a('orm:RoleSequence/*')
            x_readings = x.elements.to_a('orm:Readings/orm:Reading/orm:Data')

            # Build an array of the Roles needed:
            role_array = x_role_sequence.map{|x| @by_id[x.attributes['ref']] }

            # puts "Reading #{x_readings.map(&:text).inspect}"
            role_sequence = get_role_sequence(role_array)

            #role_sequence.all_role_ref.each_with_index{|rr, i|
            #   # REVISIT: rr.leading_adjective = ...; Add adjectives here
            #  }

            x_readings.each_with_index{|x, i|
              reading = @constellation.Reading(fact_type, fact_type.all_reading.size)
              reading.role_sequence = role_sequence
              reading.reading_text = extract_adjectives(x.text, role_sequence)
            }
          }
        }
        # @vocabulary.fact_types.each{|ft| puts ft }
      end

      def extract_adjectives(reading_text, role_sequence)
        (0...role_sequence.all_role_ref.size).each{|i|
          role_ref = role_sequence.all_role_ref[i]
          role = role_ref.role

          word = '\b([A-Za-z][A-Za-z0-9_]*)\b'
          leading_adjectives_re = "(?:#{word}- *(?:#{word} +)?)"
          trailing_adjectives_re = "(?: +(?:#{word} +) *-#{word}?)"
          role_with_adjectives_re =
            %r| ?#{leading_adjectives_re}?\{#{i}\}#{trailing_adjectives_re}? ?|

          reading_text.gsub!(role_with_adjectives_re) {
            la = [[$1]*"", [$2]*""]*" ".gsub(/\s+/, ' ').sub(/\s+\Z/,'').strip
            ta = [[$1]*"", [$2]*""]*" ".gsub(/\s+/, ' ').sub(/\A\s+/,'').strip
            #puts "Setting leading adj #{la.inspect} from #{reading_text.inspect} for #{role_ref.role.concept.name}" if la != ""
            # REVISIT: Dunno what's up here, but removing the "if" test makes this chuck exceptions:
            role_ref.leading_adjective = la if la != ""
            role_ref.trailing_adjective = ta if ta != ""

            #puts "Reading '#{reading_text}' has role #{i} adjectives '#{la}' '#{ta}'" if la != "" || ta != ""

            " {#{i}} "
          }
        }
        reading_text.sub!(/\A /, '')
        reading_text.sub!(/ \Z/, '')
        reading_text
      end

      def get_role_sequence(role_array)
        # puts "Getting RoleSequence [#{role_array.map{|r| "#{r.concept.name} (role #{r.object_id})" }*", "}]"

        # Look for an existing RoleSequence
        # REVISIT: This searches all role sequences. Perhaps we could narrow it down first instead?
        role_sequence = @constellation.RoleSequence.values.detect{|c|
          #puts "Checking RoleSequence [#{c.all_role_ref.map{|rr| rr.role.concept.name}*", "}]"
          role_array == c.all_role_ref.map{|rr| rr.role }
          }
        # puts "Found matching RoleSequence!" if role_sequence
        return role_sequence if role_sequence

        # Make a new RoleSequence:
        role_sequence = @constellation.RoleSequence(:new) unless role_sequence
        role_array.each_with_index{|r, i|
          role_ref = @constellation.RoleRef(role_sequence, i)
          role_ref.role = r
          }
        role_sequence
      end

      def map_roles(x_roles, why = nil)
        role_array = x_roles.map{|x|
          id = x.attributes['ref']
          role = @by_id[id]
          if (why && !role)
            # We didn't make Implied objects, so some constraints are unconnectable
            x_role = @x_by_id[id]
            x_player = x_role.elements.to_a('orm:RolePlayer')[0]
            x_object = @x_by_id[x_player.attributes['ref']]
            x_nests = nil
            if (x_object.name.to_s == 'ObjectifiedType')
              x_nests = x_object.elements.to_a('orm:NestedPredicate')[0]
              implied = x_nests.attributes['IsImplied']
              x_fact = @x_by_id[x_nests.attributes['ref']]
            end

            # This might have been a role of an ImpliedFact, which makes it safe to ignore.
            next if 'ImpliedFact' == x_role.parent.parent.name

            # Talk about why this wasn't found - this shouldn't happen.
            if (!x_nests || !implied)
              #puts "="*60
              puts "Skipping #{why}, #{x_role.name} #{id} not found"

              if (x_nests)
                puts "Role is on #{implied ? "implied " : ""}objectification #{x_object}"
                puts "which objectifies #{x_fact}"
              end
              puts x_object.to_s
            end
          end
          role
        }
        role_array.include?(nil) ? nil : get_role_sequence(role_array)
      end

      def read_constraints
        @constraints_by_rs = {}

        read_mandatory_constraints
        read_uniqueness_constraints
        read_exclusion_constraints
        read_subset_constraints
        read_ring_constraints
        read_equality_constraints
        read_frequency_constraints
        read_residual_mandatory_constraints
      end

      def read_mandatory_constraints
        x_mandatory_constraints = @x_model.elements.to_a("orm:Constraints/orm:MandatoryConstraint")
        @mandatory_constraints_by_rs = {}
        @mandatory_constraint_rs_by_id = {}
        x_mandatory_constraints.each{|x|
          name = x.attributes["Name"] || ''
          name.gsub!(/\s/,'')
          name = nil if name.size == 0

          # As of Feb 2008, all NORMA ValueTypes have an implied mandatory constraint.
          if x.elements.to_a("orm:ImpliedByObjectType").size > 0
            # $stderr.puts "Skipping ImpliedMandatoryConstraint #{name} over #{roles}"
            next
          end

          x_roles = x.elements.to_a("orm:RoleSequence/orm:Role")
          roles = map_roles(x_roles, "mandatory constraint #{name}")
          next if !roles

          # If X-OR mandatory, the Exclusion is accessed by:
    #       x_exclusion = (ex = x.elements.to_a("orm:ExclusiveOrExclusionConstraint")[0]) &&
    #             @x_by_id[ex.attributes['ref']]
    #       puts "Mandatory #{name}(#{roles}) is paired with exclusive #{x_exclusion.attributes['Name']}" if x_exclusion

          @mandatory_constraints_by_rs[roles] = x
          @mandatory_constraint_rs_by_id[x.attributes['id']] = roles
        }
      end

      def read_residual_mandatory_constraints
        @mandatory_constraints_by_rs.each { |roles, x|
          # Create a simply-mandatory PresenceConstraint for each mandatory constraint
          name = x.attributes["Name"] || ''
          name.gsub!(/\s/,'')
          name = nil if name.size == 0
          #puts "Residual Mandatory #{name}: #{roles.to_s}"

          pc = @constellation.PresenceConstraint(:new)
          pc.vocabulary = @vocabulary
          pc.name = name
          pc.role_sequence = roles
          pc.is_mandatory = true
          pc.min_frequency = 1 
          pc.max_frequency = nil
          pc.is_preferred_identifier = false

          (@constraints_by_rs[roles] ||= []) << pc
        }
      end

      def read_uniqueness_constraints
        x_uniqueness_constraints = @x_model.elements.to_a("orm:Constraints/orm:UniquenessConstraint")
        x_uniqueness_constraints.each{|x|
          name = x.attributes["Name"] || ''
          name.gsub!(/\s/,'')
          name = nil if name.size == 0
          id = x.attributes["id"]
          x_pi = x.elements.to_a("orm:PreferredIdentifierFor")[0]
          pi = x_pi ? @by_id[eref = x_pi.attributes['ref']] : nil

          # Skip uniqueness constraints on implied concepts
          if x_pi && !pi
            puts "Skipping uniqueness constraint #{name}, entity not found"
            next
          end

          # A uniqueness constraint on a fact having an implied objectification isn't preferred:
  #       if pi &&
  #         (x_pi_for = @x_by_id[eref]) &&
  #         (np = x_pi_for.elements.to_a('orm:NestedPredicate')[0]) &&
  #         np.attributes['IsImplied']
  #           pi = nil
  #       end

          # Get the RoleSequence:
          x_roles = x.elements.to_a("orm:RoleSequence/orm:Role")
          next if x_roles.size == 0
          roles = map_roles(x_roles, "uniqueness constraint #{name}")
          next if !roles

          # There is an implicit uniqueness constraint when any object plays a unary. Skip it.
          if (x_roles.size == 1 &&
            (id = x_roles[0].attributes['ref']) &&
            (x_role = @x_by_id[id]) &&
            x_role.parent.elements.size == 2 &&
            (sibling = x_role.parent.elements[2]) &&
            (ib_id = sibling.elements[1].attributes['ref']) &&
            (ib = @x_by_id[ib_id]) &&
            ib.attributes['IsImplicitBooleanValue'])
          next  # Skip uniqueness constraint over our role in this implicit boolean
          end

          if (mc = @mandatory_constraints_by_rs[roles])
            # Remove absorbed mandatory constraints, leaving residual ones.
            # puts "Absorbing MC #{mc.attributes['Name']}"
            @mandatory_constraints_by_rs.delete(roles)
            @mandatory_constraint_rs_by_id.delete(mc.attributes['id'])
          end

          # A UC that spans more than one Role of a fact will be a Preferred Id for the implied object
          #puts "Unique" + rs.to_s +
          #    (pi ? " (preferred id for #{pi.name})" : "") +
          #    (mc ? " (mandatory)" : "") if pi && !mc

          pc = @constellation.PresenceConstraint(:new)
          pc.vocabulary = @vocabulary
          pc.name = name
          pc.role_sequence = roles
          pc.is_mandatory = true if mc
          pc.min_frequency = mc ? 1 : 0
          pc.max_frequency = 1 
          pc.is_preferred_identifier = true if pi

          #puts roles.verbalise
          #puts pc.verbalise

          (@constraints_by_rs[roles] ||= []) << pc
        }
      end

      def read_exclusion_constraints
        x_exclusion_constraints = @x_model.elements.to_a("orm:Constraints/orm:ExclusionConstraint")
        x_exclusion_constraints.each{|x|
          name = x.attributes["Name"] || ''
          name.gsub!(/\s/,'')
          name = nil if name.size == 0
          x_mandatory = (m = x.elements.to_a("orm:ExclusiveOrMandatoryConstraint")[0]) &&
                  @x_by_id[mc_id = m.attributes['ref']]
          role_sequences = 
            x.elements.to_a("orm:RoleSequences/orm:RoleSequence").map{|x_rs|
                x_role_refs = x_rs.elements.to_a("orm:Role")
                map_roles(
                  x_role_refs , # .map{|xr| @x_by_id[xr.attributes['ref']] },
                  "exclusion constraint #{name}"
                )
              }
          if x_mandatory
            # Remove absorbed mandatory constraints, leaving residual ones.
            mc_rs = @mandatory_constraint_rs_by_id[mc_id]
            @mandatory_constraint_rs_by_id.delete(mc_id)
            @mandatory_constraints_by_rs.delete(mc_rs)
          end

          ec = @constellation.SetExclusionConstraint(:new)
          ec.vocabulary = @vocabulary
          ec.name = name
          # ec.enforcement = 
          role_sequences.each{|rs|
            @constellation.SetComparisonRoles(ec, rs)
          }
          ec.is_mandatory = true if x_mandatory
        }
      end

      def read_equality_constraints
        x_equality_constraints = @x_model.elements.to_a("orm:Constraints/orm:EqualityConstraint")
        x_equality_constraints.each{|x|
          name = x.attributes["Name"] || ''
          name.gsub!(/\s/,'')
          name = nil if name.size == 0
          role_sequences = 
            x.elements.to_a("orm:RoleSequences/orm:RoleSequence").map{|x_rs|
                x_role_refs = x_rs.elements.to_a("orm:Role")
                map_roles(
                  x_role_refs , # .map{|xr| @x_by_id[xr.attributes['ref']] },
                  "equality constraint #{name}"
                )
              }

          ec = @constellation.SetEqualityConstraint(:new)
          ec.vocabulary = @vocabulary
          ec.name = name
          # ec.enforcement = 
          role_sequences.each{|rs|
            @constellation.SetComparisonRoles(ec, rs)
          }
        }
      end

      def read_subset_constraints
        x_subset_constraints = @x_model.elements.to_a("orm:Constraints/orm:SubsetConstraint")
        x_subset_constraints.each{|x|
          name = x.attributes["Name"] || ''
          name.gsub!(/\s/,'')
          name = nil if name.size == 0
          role_sequences = 
            x.elements.to_a("orm:RoleSequences/orm:RoleSequence").map{|x_rs|
                x_role_refs = x_rs.elements.to_a("orm:Role")
                map_roles(
                  x_role_refs , # .map{|xr| @x_by_id[xr.attributes['ref']] },
                  "equality constraint #{name}"
                )
              }

          ec = @constellation.SubsetConstraint(:new)
          ec.vocabulary = @vocabulary
          ec.name = name
          # ec.enforcement = 
          ec.superset_role_sequence = role_sequences[0]
          ec.subset_role_sequence = role_sequences[1]
        }
      end

      def read_ring_constraints
        x_ring_constraints = @x_model.elements.to_a("orm:Constraints/orm:RingConstraint")
        x_ring_constraints.each{|x|
          name = x.attributes["Name"] || ''
          name.gsub!(/\s/,'')
          name = nil if name.size == 0
          type = x.attributes["Type"]
  #       begin
  #         # Convert the RingConstraint name to a number:
  #         type_num = eval("::ActiveFacts::RingConstraint::#{type}") 
  #       rescue => e
  #         throw "RingConstraint type #{type} isn't known"
  #       end

          from, to = *x.elements.to_a("orm:RoleSequence/orm:Role").map{|xr|
                  @by_id[xr.attributes['ref']]
                }
          rc = @constellation.RingConstraint(:new)
          rc.vocabulary = @vocabulary
          rc.name = name
          # rc.enforcement = 
          rc.role = from
          rc.other_role = to
          rc.ring_type = type
        }
      end

      def read_frequency_constraints
        x_frequency_constraints = @x_model.elements.to_a("orm:Constraints/orm:FrequencyConstraint")
        # REVISIT: FrequencyConstraints not handled yet
      end

      def read_instances
        population = Population.new(@vocabulary, "sample")

        # Value instances first, then entities then facts:

        x_values = @x_model.elements.to_a("orm:Objects/orm:ValueType/orm:Instances/orm:ValueTypeInstance/orm:Value")
        #pp x_values.map{|v| [ v.parent.attributes['id'], v.text ] }
        x_values.each{|v|
          id = v.parent.attributes['id']
          # Get details of the ValueType:
          xvt = v.parent.parent.parent
          vt_id = xvt.attributes['id']
          vtname = xvt.attributes['Name'] || ''
          vtname.gsub!(/\s/,'')
          vtname = nil if name.size == 0
          vt = @by_id[vt_id]
          throw "ValueType #{vtname} not found" unless vt

          i = Instance.new(vt, v.text)
          @by_id[id] = i
          # show_xmlobj(v)
        }

        # Use the "id" attribute of EntityTypeInstance
        x_entities = @x_model.elements.to_a("orm:Objects/orm:EntityType/orm:Instances/orm:EntityTypeInstance")
        #pp x_entities
        # x_entities.each{|v| show_xmlobj(v) }
        last_et_id = nil
        last_et = nil
        et = nil
        x_entities.each{|v|
          id = v.attributes['id']

          # Get details of the EntityType:
          xet = v.parent.parent
          et_id = xet.attributes['id']
          if (et_id != last_et_id)
            etname = xet.attributes['Name'] || ''
            etname.gsub!(/\s/,'')
            etname = nil if name.size == 0
            last_et = et = @by_id[et_id]
            last_et_id = et_id
            throw "EntityType #{etname} not found" unless et
          end

          instance = Instance.new(et)
          @by_id[id] = instance
          # puts "Made new EntityType #{etname}"
        }

        # The EntityType instances have implicit facts for the PI facts.
        # We must create implicit PI facts after all the instances.
        entity_count = 0
        pi_fact_count = 0
        x_entities.each{|v|
          id = v.attributes['id']
          instance = @by_id[id]
          et = @by_id[v.parent.parent.attributes['id']]
          next unless (preferred_id = et.preferred_identifier)

          # puts "Create identifying facts using #{preferred_id}"

          # Collate the referenced objects by role:
          role_instances = v.elements[1].elements.inject({}){|h, v|
              etri = @x_by_id[v.attributes['ref']]
              x_role_id = etri.parent.parent.attributes['id']
              role = @by_id[x_role_id]
              object = @by_id[object_id = etri.attributes['ref']]
              h[role] = object
              h
            }

          # Create an instance of each required fact type, for compound identification:
          preferred_id.role_sequence.map(&:fact_type).uniq.each{|ft|
            # puts "\tFor FactType #{ft}"
            fact_roles = ft.roles.map{|role|
              if role.concept == et
                object = instance
              else
                object = role_instances[role]
                # puts "\t\tinstance for role #{role} is #{object}"
              end
              FactRole.new(role, object)
            }
            f = Fact.new(population, ft, *fact_roles)
            pi_fact_count += 1
          }
          entity_count += 1
        }
        # puts "Created #{pi_fact_count} facts to identify #{entity_count} entities"

        # Use the "ref" attribute of FactTypeRoleInstance:
        x_fact_roles = @x_model.elements.to_a("orm:Facts/orm:Fact/orm:Instances/orm:FactTypeInstance/orm:RoleInstances/orm:FactTypeRoleInstance")

        last_id = nil
        last_fact_type = nil
        fact_roles = []
        x_fact_roles.each{|v|
          fact_type_id = v.parent.parent.parent.parent.attributes['id']
          id = v.parent.parent.attributes['id']
          fact_type = @by_id[fact_type_id]
          throw "Fact type #{fact_type_id} not found" unless fact_type

          if (last_id && id != last_id)
            # Process completed fact now we have all roles:
            last_fact = Fact.new(population, last_fact_type, *fact_roles)
            fact_roles = []
          else
            last_fact_type = fact_type
          end

          #show_xmlobj(v)

          last_id = id
          x_role_instance = @x_by_id[v.attributes['ref']]
          x_role_id = x_role_instance.parent.parent.attributes['id']
          role = @by_id[x_role_id]
          throw "Role not found for instance #{x_role_id}" unless role
          instance_id = x_role_instance.attributes['ref']
          instance = @by_id[instance_id]
          throw "Instance not found for FactRole #{instance_id}" unless instance
          fact_roles << FactRole.new(role, instance)
        }

        if (last_id)
          # Process final completed fact now we have all roles:
          last_fact = Fact.new(population, last_fact_type, *fact_roles)
        end

      end

      def read_rest
        puts "Reading Implied Facts (not yet)"
=begin
        x_implied_facts = @x_model.elements.to_a("orm:Facts/orm:ImpliedFact")
        pp x_implied_facts
=end
        puts "Reading Data Types (not yet)"
=begin
        x_datatypes = @x_model.elements.to_a("orm:DataTypes/*")
        pp x_datatypes
=end
        puts "Reading Reference Mode Kinds (not yet)"
=begin
        x_refmodekinds = @x_model.elements.to_a("orm:ReferenceModeKinds/*")
        pp x_refmodekinds
=end
      end

      def show_xmlobj(x, indent = "")
        parentage = []
        p = x
        while (p)
          parentage.unshift(p)
          p = p.parent
        end
        #parentage = parentage.shift
        puts "#{indent}#{x.name} object has heritage {"
        parentage.each{|p|
          next if REXML::Document === p
          puts "#{indent}\t#{p.name}#{
            }#{(n = p.attributes['Name']) ? " Name='#{n}'" : ""
            }#{(id = p.attributes['id']) ? " #{id}" : ""
            }#{(ref = p.attributes['ref']) ? " -> #{ref}" : ""
            }#{/\S/ === ((text = p.text)) ? " "+text.inspect : ""
            }"
          show_xmlobj(@x_by_id[ref], "\t#{indent}") if ref
        }
        puts "#{indent}}"
      end
    end
  end
end
