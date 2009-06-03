#
#       ActiveFacts Vocabulary Input.
#       Read a NORMA file into an ActiveFacts vocabulary
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
# This code uses variables prefixed with x_ when they refer to Rexml nodes.
# Every node having an id="..." is indexed in @x_by_id[] hash before processing.
# As we build ActiveFacts objects to match, we index those in @by_id[].
# Both these hashes may be looked up by any of the ref="..." values in the file.
#
require 'nokogiri'
require 'activefacts/vocabulary'

module Nokogiri
  module XML
    class Node
      def elements
        children.select{|n|
          Nokogiri::XML::Element === n
        }
      end
    end
  end
end

module ActiveFacts
  module Input
    # Compile a NORMA (.orm) file to an ActiveFacts vocabulary.
    # Invoke as
    #   afgen --<generator> <file>.orm
    # This parser uses Rexml so it's very slow.
    class ORM
    private
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

    public
      def read          #:nodoc:
        begin
          @document = Nokogiri::XML(@file)
        rescue => e
          puts "Failed to parse XML in #{@filename}: #{e.inspect}"
        end

        # Find the Vocabulary and do some setup:
        root = @document.root
        #p((root.methods-0.methods).sort.grep(/name/))
        if root.name == "ORM2" && root.namespace == "ormRoot"
          x_models = root.xpath('orm:ORMModel')
          throw "No vocabulary found" unless x_models.size == 1
          @x_model = x_models[0]
        elsif root.name == "ORMModel"
          p @document.children.map(&:name)
          @x_model = @document.children[0]
        else
          throw "NORMA model not found in #{@filename}"
        end

        read_vocabulary
        @vocabulary
      end

    private

      def read_vocabulary
        @constellation = ActiveFacts::API::Constellation.new(ActiveFacts::Metamodel)
        vocabulary_name = @x_model['Name']
        @vocabulary = @constellation.Vocabulary(@x_model['Name'])

        # Find all elements having an "id" attribute and index them
        x_identified = @x_model.xpath(".//*[@id]")
        @x_by_id = x_identified.inject({}){|h, x|
          id = x['id']
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
        x_entity_types = @x_model.xpath("orm:Objects/orm:EntityType")
        x_entity_types.each{|x|
          id = x['id']
          name = x['Name'] || ""
          name.gsub!(/\s/,'')
          name = nil if name.size == 0
          entity_types <<
            @by_id[id] =
              entity_type =
              @constellation.EntityType(@vocabulary, name)
            independent = x['IsIndependent']
            entity_type.is_independent = true if independent && independent == 'true'
            personal = x['IsPersonal']
            entity_type.pronoun = 'personal' if personal && personal == 'true'
  #       x_pref = x.xpath("orm:PreferredIdentifier")[0]
  #       if x_pref
  #         pi_id = x_pref['ref']
  #         @pref_id_for[pi_id] = x
  #       end
        }
      end

      def read_value_types
        # Now the value types:
        value_types = []
        x_value_types = @x_model.xpath("orm:Objects/orm:ValueType")
        #pp x_value_types
        x_value_types.each{|x|
          id = x['id']
          name = x['Name'] || ""
          name.gsub!(/\s/,'')
          name = nil if name.size == 0

          cdt = x.xpath('orm:ConceptualDataType')[0]
          scale = cdt['Scale']
          scale = scale != "" && scale.to_i
          length = cdt['Length']
          length = length != "" && length.to_i
          base_type = @x_by_id[cdt['ref']]
          type_name = "#{base_type.name}"
          type_name.sub!(/^orm:/,'')
          type_name.sub!(/DataType\Z/,'')
          type_name.sub!(/Numeric\Z/,'')
          type_name.sub!(/Temporal\Z/,'')
          length = 32 if type_name =~ /Integer\Z/ && length.to_i == 0 # Set default integer length

          # REVISIT: Need to handle standard types better here:
          value_super_type = type_name != name ? @constellation.ValueType(@vocabulary, type_name) : nil

          value_types <<
            @by_id[id] =
            vt = @constellation.ValueType(@vocabulary, name)
          vt.supertype = value_super_type
          vt.length = length if length
          vt.scale = scale if scale
          independent = x['IsIndependent']
          vt.is_independent = true if independent && independent == 'true'
          personal = x['IsPersonal']
          vt.pronoun = 'personal' if personal && personal == 'true'

          x_ranges = x.xpath("orm:ValueRestriction/orm:ValueConstraint/orm:ValueRanges/orm:ValueRange")
          next if x_ranges.size == 0
          vt.value_restriction = @constellation.ValueRestriction(:new)
          x_ranges.each{|x_range|
            v_range = value_range(x_range)
            ar = @constellation.AllowedRange(vt.value_restriction, v_range)
          }
        }
      end

      def value_range(x_range)
        min = x_range['MinValue']
        max = x_range['MaxValue']
        q = "'"
        min = case min
          when ""; nil
          when /[^0-9\.]/; q+min+q
          when /\./; Float(min)
          else Integer(min)
          end
        max = case max
          when ""; nil
          when /[^0-9\.]/; q+max+q
          when /\./; Float(max)
          else Integer(max)
          end
        # ValueRange takes a minimum and/or a maximum Bound, each takes value and whether inclusive
        @constellation.ValueRange(
            min ? [min.to_s, true] : nil,
            max ? [max.to_s, true] : nil
          )
      end

      def read_fact_types
        # Handle the fact types:
        facts = []
        @x_facts = @x_model.xpath("orm:Facts/orm:Fact")
        @x_facts.each{|x|
          id = x['id']
          name = x['Name'] || x['_Name']
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
        @x_subtypes = @x_model.xpath("orm:Facts/orm:SubtypeFact")
        if @document.namespaces['xmlns:oialtocdb']
          oialtocdb = @document.xpath("ormRoot:ORM2/oialtocdb:MappingCustomization")
          @x_mappings = oialtocdb.xpath(".//oialtocdb:AssimilationMappings/oialtocdb:AssimilationMapping/oialtocdb:FactType")
        else
          @x_mappings = []
        end

        @x_subtypes.each{|x|
          id = x['id']
          name = x['Name'] || x['_Name'] || ''
          name.gsub!(/\s/,'')
          name = nil if name.size == 0
          # puts "FactType #{name || id}"

          x_subtype_role = x.xpath('orm:FactRoles/orm:SubtypeMetaRole')[0]
          subtype_role_id = x_subtype_role['id']
          subtype_id = x_subtype_role.xpath('orm:RolePlayer')[0]['ref']
          subtype = @by_id[subtype_id]
          # REVISIT: Provide a way in the metamodel of handling Partition, (and mapping choices that vary for each supertype?)

          x_supertype_role = x.xpath('orm:FactRoles/orm:SupertypeMetaRole')[0]
          supertype_role_id = x_supertype_role['id']
          supertype_id = x_supertype_role.xpath('orm:RolePlayer')[0]['ref']
          supertype = @by_id[supertype_id]

          throw "For Subtype fact #{name}, the supertype #{supertype_id} was not found" if !supertype
          throw "For Subtype fact #{name}, the subtype #{subtype_id} was not found" if !subtype
          # $stderr.puts "#{subtype.name} is a subtype of #{supertype.name}"

          inheritance_fact = @constellation.TypeInheritance(subtype, supertype)
          inheritance_fact.fact_type_id = :new
          if x["IsPrimary"] == "true" or           # Old way
            x["PreferredIdentificationPath"] == "true"   # Newer
            # $stderr.puts "#{supertype.name} is primary supertype of #{subtype.name}"
            inheritance_fact.provides_identification = true
          end
          mapping = @x_mappings.detect{ |m| m['ref'] == id }
          mapping_choice = mapping ? mapping.parent['AbsorptionChoice'] : 'Absorbed'
          inheritance_fact.assimilation = mapping_choice.downcase if mapping_choice != 'Absorbed'
          facts << @by_id[id] = inheritance_fact

          # Create the new Roles so we can find constraints on them:
          subtype_role = @by_id[subtype_role_id] = @constellation.Role(inheritance_fact, 0, subtype)
          supertype_role = @by_id[supertype_role_id] = @constellation.Role(inheritance_fact, 1, supertype)

          # Create readings, so constraints can be verbalised for example:
          rs = @constellation.RoleSequence(:new)
          @constellation.RoleRef(rs, 0).role = subtype_role
          @constellation.RoleRef(rs, 1).role = supertype_role

#          reading = @constellation.Reading(inheritance_fact, 0)
#          reading.text = "{1} is {0}"
#          reading.role_sequence = rs

          reading = @constellation.Reading(inheritance_fact, 0)
          reading.text = "{0} is a subtype of {1}"
          reading.role_sequence = rs

          # The required uniqueness constraints are already present in the NORMA file, don't duplicate them
=begin
          # Create uniqueness constraints over the subtyping fact type
          p1rs = @constellation.RoleSequence(:new)
          @constellation.RoleRef(p1rs, 0).role = subtype_role
          pc1 = @constellation.PresenceConstraint(:new)
          pc1.name = "#{subtype.name}MustHaveSupertype#{supertype.name}"
          pc1.vocabulary = @vocabulary
          pc1.role_sequence = p1rs
          pc1.is_mandatory = true   # A subtype instance must have a supertype instance
          pc1.min_frequency = 1
          pc1.max_frequency = 1
          pc1.is_preferred_identifier = false

          # The supertype role often identifies the subtype:
          p2rs = @constellation.RoleSequence(:new)
          @constellation.RoleRef(p2rs, 0).role = supertype_role
          pc2 = @constellation.PresenceConstraint(:new)
          pc2.name = "#{supertype.name}MayBeA#{subtype.name}"
          pc2.vocabulary = @vocabulary
          pc2.role_sequence = p2rs
          pc2.is_mandatory = false
          pc2.min_frequency = 0
          pc2.max_frequency = 1
          pc2.is_preferred_identifier = inheritance_fact.provides_identification
=end
        }
      end

      def read_nested_types
        # Process NestedTypes, but ignore ones having a NestedPredicate with IsImplied="true"
        # We'll ignore the fact roles (and constraints) that implied objectifications have.
        # This happens for all ternaries and higher order facts
        nested_types = []
        x_nested_types = @x_model.xpath("orm:Objects/orm:ObjectifiedType")
        x_nested_types.each{|x|
          id = x['id']
          name = x['Name'] || ""
          name.gsub!(/\s/,'')
          name = nil if name.size == 0

          x_fact_type = x.xpath('orm:NestedPredicate')[0]
          is_implied = x_fact_type['IsImplied'] == "true"

          fact_id = x_fact_type['ref']
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
              nested_type = @constellation.EntityType(@vocabulary, name)
            nested_type.fact_type = fact_type
          end
        }
      end

      def read_roles
        @x_facts.each{|x|
          id = x['id']
          fact_type = @by_id[id]
          fact_name = x['Name'] || x['_Name'] || ''
          fact_name.gsub!(/\s/,'')
          fact_name = nil if fact_name == ''

          x_fact_roles = x.xpath('orm:FactRoles/*')
          x_reading_orders = x.xpath('orm:ReadingOrders/*')

          # Deal with FactRoles (Roles):
          x_fact_roles.each{|x|
            name = x['Name'] || ""
            name.gsub!(/\s/,'')
            name = nil if name.size == 0

            # _IsMandatory = x['_IsMandatory']
            # _Multiplicity = x['_Multiplicity]
            id = x['id']
            ref = x.xpath('orm:RolePlayer')[0]['ref']

            # Find the concept that plays the role:
            concept = @by_id[ref]
            throw "RolePlayer for '#{name}' #{ref} was not found" if !concept

            # Skip implicit roles added by NORMA to make unaries into binaries.
            # This would make constraints over the deleted roles impossible,
            # so as a SPECIAL CASE we index the unary role by the id of the
            # implicit role. That means care is needed when handling unary FTs.
            if (ox = @x_by_id[ref]) && ox['IsImplicitBooleanValue']
              x_other_role = x.parent.xpath('orm:Role').reject{|x_role|
                  x_role == x
                }[0]
              other_role_id = x_other_role["id"]
              other_role = @by_id[other_role_id]
              # puts "Indexing unary FT role #{other_role_id} by implicit boolean role #{id}"
              @by_id[id] = other_role

              # The role name of the ignored role is the one that applies:
              role_name = x['Name']
              other_role.role_name = role_name if role_name && role_name != ''

              concept.delete    # Delete our object for the implicit boolean ValueType
              @by_id.delete(ref)    # and de-index it from our list
              next
            end

            #puts "#{@vocabulary}, Name=#{x['Name']}, concept=#{concept}"
            throw "Role is played by #{concept.class} not Concept" if !(@constellation.vocabulary.concept(:Concept) === concept)

            name = x['Name'] || ''
            name.gsub!(/\s/,'')
            name = nil if name.size == 0
            #puts "Creating role #{name} nr#{fact_type.all_role.size} of #{fact_type.fact_type_id} played by #{concept.name}"

            role = @by_id[id] = @constellation.Role(fact_type, fact_type.all_role.size, concept)
            role.role_name = name if name
            # puts "Fact #{fact_name} (id #{fact_type.fact_type_id.object_id}) role #{x['Name']} is played by #{concept.name}, role is #{role.object_id}"

            x_vr = x.xpath("orm:ValueRestriction")
            x_vr.each{|vr|
              x_ranges = vr.xpath("orm:RoleValueConstraint/orm:ValueRanges/orm:ValueRange")
              next if x_ranges.size == 0
              role.role_value_restriction = @constellation.ValueRestriction(:new)
              x_ranges.each{|x_range|
                v_range = value_range(x_range)
                ar = @constellation.AllowedRange(role.role_value_restriction, v_range)
              }
            }

            # puts "Adding Role #{role.name} to #{fact_type.name}"
            #fact_type.add_role(role)
            # puts "\tRole #{role} is #{id}"
          }

          # Deal with Readings:
          x_reading_orders.each{|x|
            x_role_sequence = x.xpath('orm:RoleSequence/*')
            x_readings = x.xpath('orm:Readings/orm:Reading/orm:Data')

            # Build an array of the Roles needed:
            role_array = x_role_sequence.map{|x| @by_id[x['ref']] }

            # puts "Reading #{x_readings.map(&:text).inspect}"
            role_sequence = get_role_sequence(role_array)

            #role_sequence.all_role_ref.each_with_index{|rr, i|
            #   # REVISIT: rr.leading_adjective = ...; Add adjectives here
            #  }

            x_readings.each_with_index{|x, i|
              reading = @constellation.Reading(fact_type, fact_type.all_reading.size)
              reading.role_sequence = role_sequence
              # REVISIT: The downcase here only needs to be the initial letter of each word, but be safe:
              reading.text = extract_adjectives(x.text, role_sequence).downcase
            }
          }
        }
        # @vocabulary.fact_types.each{|ft| puts ft }
      end

      def extract_adjectives(text, role_sequence)
        all_role_refs = role_sequence.all_role_ref.sort_by{|rr| rr.ordinal}
        (0...all_role_refs.size).each{|i|
          role_ref = all_role_refs[i]
          role = role_ref.role

          word = '\b([A-Za-z][A-Za-z0-9_]*)\b'
          leading_adjectives_re = "(?:#{word}- *(?:#{word} +)?)"
          trailing_adjectives_re = "(?: +(?:#{word} +) *-#{word}?)"
          role_with_adjectives_re =
            %r| ?#{leading_adjectives_re}?\{#{i}\}#{trailing_adjectives_re}? ?|

          text.gsub!(role_with_adjectives_re) {
            la = [[$1]*"", [$2]*""]*" ".gsub(/\s+/, ' ').sub(/\s+\Z/,'').strip
            ta = [[$1]*"", [$2]*""]*" ".gsub(/\s+/, ' ').sub(/\A\s+/,'').strip
            #puts "Setting leading adj #{la.inspect} from #{text.inspect} for #{role_ref.role.concept.name}" if la != ""
            # REVISIT: Dunno what's up here, but removing the "if" test makes this chuck exceptions:
            role_ref.leading_adjective = la if la != ""
            role_ref.trailing_adjective = ta if ta != ""

            #puts "Reading '#{text}' has role #{i} adjectives '#{la}' '#{ta}'" if la != "" || ta != ""

            " {#{i}} "
          }
        }
        text.sub!(/\A /, '')
        text.sub!(/ \Z/, '')
        text
      end

      def get_role_sequence(role_array)
        # puts "Getting RoleSequence [#{role_array.map{|r| "#{r.concept.name} (role #{r.object_id})" }*", "}]"

        # Look for an existing RoleSequence
        # REVISIT: This searches all role sequences. Perhaps we could narrow it down first instead?
        role_sequence = @constellation.RoleSequence.values.detect{|c|
          #puts "Checking RoleSequence [#{c.all_role_ref.map{|rr| rr.role.concept.name}*", "}]"
          role_array == c.all_role_ref.sort_by{|rr| rr.ordinal}.map{|rr| rr.role }
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
          id = x['ref']
          role = @by_id[id]
          if (why && !role)
            # We didn't make Implied objects, so some constraints are unconnectable
            x_role = @x_by_id[id]
            x_player = x_role.xpath('orm:RolePlayer')[0]
            x_object = @x_by_id[x_player['ref']]
            x_nests = nil
            if (x_object.name.to_s == 'ObjectifiedType')
              x_nests = x_object.xpath('orm:NestedPredicate')[0]
              implied = x_nests['IsImplied']
              x_fact = @x_by_id[x_nests['ref']]
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
        x_mandatory_constraints = @x_model.xpath("orm:Constraints/orm:MandatoryConstraint")
        @mandatory_constraints_by_rs = {}
        @mandatory_constraint_rs_by_id = {}
        x_mandatory_constraints.each{|x|
          name = x["Name"] || ''
          name.gsub!(/\s/,'')
          name = nil if name.size == 0

          # As of Feb 2008, all NORMA ValueTypes have an implied mandatory constraint.
          if x.xpath("orm:ImpliedByObjectType").size > 0
            # $stderr.puts "Skipping ImpliedMandatoryConstraint #{name} over #{roles}"
            next
          end

          x_roles = x.xpath("orm:RoleSequence/orm:Role")
          roles = map_roles(x_roles, "mandatory constraint #{name}")
          next if !roles

          # If X-OR mandatory, the Exclusion is accessed by:
    #       x_exclusion = (ex = x.xpath("orm:ExclusiveOrExclusionConstraint")[0]) &&
    #             @x_by_id[ex['ref']]
    #       puts "Mandatory #{name}(#{roles}) is paired with exclusive #{x_exclusion['Name']}" if x_exclusion

          @mandatory_constraints_by_rs[roles] = x
          @mandatory_constraint_rs_by_id[x['id']] = roles
        }
      end

      def read_residual_mandatory_constraints
        @mandatory_constraints_by_rs.each { |roles, x|
          # Create a simply-mandatory PresenceConstraint for each mandatory constraint
          name = x["Name"] || ''
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
        x_uniqueness_constraints = @x_model.xpath("orm:Constraints/orm:UniquenessConstraint")
        x_uniqueness_constraints.each{|x|
          name = x["Name"] || ''
          name.gsub!(/\s/,'')
          name = nil if name.size == 0
          id = x["id"]
          x_pi = x.xpath("orm:PreferredIdentifierFor")[0]
          pi = x_pi ? @by_id[eref = x_pi['ref']] : nil

          # Skip uniqueness constraints on implied concepts
          if x_pi && !pi
            puts "Skipping uniqueness constraint #{name}, entity not found"
            next
          end

          # A uniqueness constraint on a fact having an implied objectification isn't preferred:
  #       if pi &&
  #         (x_pi_for = @x_by_id[eref]) &&
  #         (np = x_pi_for.xpath('orm:NestedPredicate')[0]) &&
  #         np['IsImplied']
  #           pi = nil
  #       end

          # Get the RoleSequence:
          x_roles = x.xpath("orm:RoleSequence/orm:Role")
          next if x_roles.size == 0
          roles = map_roles(x_roles, "uniqueness constraint #{name}")
          next if !roles

          # There is an implicit uniqueness constraint when any object plays a unary. Skip it.
          if (x_roles.size == 1 &&
              (id = x_roles[0]['ref']) &&
              (x_role = @x_by_id[id]) &&
              (nodes = x_role.parent.elements).size == 2 &&
              (sibling = nodes[1]) &&
#              x_role.parent.children.size == 2 &&
#              (sibling = x_role.parent.children[1]) &&
              (ib_id = sibling.elements[0]['ref']) &&
              (ib = @x_by_id[ib_id]) &&
              ib['IsImplicitBooleanValue'])
            unary_identifier = true
          end

          if (mc = @mandatory_constraints_by_rs[roles])
            # Remove absorbed mandatory constraints, leaving residual ones.
            # puts "Absorbing MC #{mc['Name']}"
            @mandatory_constraints_by_rs.delete(roles)
            @mandatory_constraint_rs_by_id.delete(mc['id'])
          end

          # A UC that spans more than one Role of a fact will be a Preferred Id for the implied object
          #puts "Unique" + rs.to_s +
          #    (pi ? " (preferred id for #{pi.name})" : "") +
          #    (mc ? " (mandatory)" : "") if pi && !mc

          # A TypeInheritance fact type has a uniqueness constraint on each role.
          # If this UC is on the supertype and identifies the subtype, it's preferred:
          is_supertype_constraint =
            (rr = roles.all_role_ref.single) &&
            (role = rr.role) &&
            (fact_type = role.fact_type) &&
            fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance) &&
            role.concept == fact_type.supertype &&
            fact_type.provides_identification

          pc = @constellation.PresenceConstraint(:new)
          pc.vocabulary = @vocabulary
          pc.name = name
          pc.role_sequence = roles
          pc.is_mandatory = true if mc
          pc.min_frequency = mc ? 1 : 0
          pc.max_frequency = 1 
          pc.is_preferred_identifier = true if pi || unary_identifier || is_supertype_constraint
          #puts "#{name} covers #{roles.describe} has min=#{pc.min_frequency}, max=1, preferred=#{pc.is_preferred_identifier.inspect}" if emit_special_debug

          #puts roles.all_role_ref.to_a[0].role.fact_type.describe + " is subject to " + pc.describe if roles.all_role_ref.all?{|r| r.role.fact_type.is_a? ActiveFacts::Metamodel::TypeInheritance }

          (@constraints_by_rs[roles] ||= []) << pc
        }
      end

      def read_exclusion_constraints
        x_exclusion_constraints = @x_model.xpath("orm:Constraints/orm:ExclusionConstraint")
        x_exclusion_constraints.each{|x|
          name = x["Name"] || ''
          name.gsub!(/\s/,'')
          name = nil if name.size == 0
          x_mandatory = (m = x.xpath("orm:ExclusiveOrMandatoryConstraint")[0]) &&
                  @x_by_id[mc_id = m['ref']]
          role_sequences = 
            x.xpath("orm:RoleSequences/orm:RoleSequence").map{|x_rs|
                x_role_refs = x_rs.xpath("orm:Role")
                map_roles(
                  x_role_refs , # .map{|xr| @x_by_id[xr['ref']] },
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
          role_sequences.each_with_index do |rs, i|
            @constellation.SetComparisonRoles(ec, i, :role_sequence => rs)
          end
          ec.is_mandatory = true if x_mandatory
        }
      end

      def read_equality_constraints
        x_equality_constraints = @x_model.xpath("orm:Constraints/orm:EqualityConstraint")
        x_equality_constraints.each{|x|
          name = x["Name"] || ''
          name.gsub!(/\s/,'')
          name = nil if name.size == 0
          role_sequences = 
            x.xpath("orm:RoleSequences/orm:RoleSequence").map{|x_rs|
                x_role_refs = x_rs.xpath("orm:Role")
                map_roles(
                  x_role_refs , # .map{|xr| @x_by_id[xr['ref']] },
                  "equality constraint #{name}"
                )
              }

          ec = @constellation.SetEqualityConstraint(:new)
          ec.vocabulary = @vocabulary
          ec.name = name
          # ec.enforcement = 
          role_sequences.each_with_index do |rs, i|
            @constellation.SetComparisonRoles(ec, i, :role_sequence => rs)
          end
        }
      end

      def read_subset_constraints
        x_subset_constraints = @x_model.xpath("orm:Constraints/orm:SubsetConstraint")
        x_subset_constraints.each{|x|
          name = x["Name"] || ''
          name.gsub!(/\s/,'')
          name = nil if name.size == 0
          role_sequences = 
            x.xpath("orm:RoleSequences/orm:RoleSequence").map{|x_rs|
                x_role_refs = x_rs.xpath("orm:Role")
                map_roles(
                  x_role_refs , # .map{|xr| @x_by_id[xr['ref']] },
                  "equality constraint #{name}"
                )
              }

          ec = @constellation.SubsetConstraint(:new)
          ec.vocabulary = @vocabulary
          ec.name = name
          # ec.enforcement = 
          ec.subset_role_sequence = role_sequences[0]
          ec.superset_role_sequence = role_sequences[1]
        }
      end

      def read_ring_constraints
        x_ring_constraints = @x_model.xpath("orm:Constraints/orm:RingConstraint")
        x_ring_constraints.each{|x|
          name = x["Name"] || ''
          name.gsub!(/\s/,'')
          name = nil if name.size == 0
          type = x["Type"]
  #       begin
  #         # Convert the RingConstraint name to a number:
  #         type_num = eval("::ActiveFacts::RingConstraint::#{type}") 
  #       rescue => e
  #         throw "RingConstraint type #{type} isn't known"
  #       end

          from, to = *x.xpath("orm:RoleSequence/orm:Role").map{|xr|
                  @by_id[xr['ref']]
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
        x_frequency_constraints = @x_model.xpath("orm:Constraints/orm:FrequencyConstraint")
        # REVISIT: FrequencyConstraints not handled yet
      end

      def read_instances
        population = Population.new(@vocabulary, "sample")

        # Value instances first, then entities then facts:

        x_values = @x_model.xpath("orm:Objects/orm:ValueType/orm:Instances/orm:ValueTypeInstance/orm:Value")
        #pp x_values.map{|v| [ v.parent['id'], v.text ] }
        x_values.each{|v|
          id = v.parent['id']
          # Get details of the ValueType:
          xvt = v.parent.parent.parent
          vt_id = xvt['id']
          vtname = xvt['Name'] || ''
          vtname.gsub!(/\s/,'')
          vtname = nil if name.size == 0
          vt = @by_id[vt_id]
          throw "ValueType #{vtname} not found" unless vt

          i = Instance.new(vt, v.text)
          @by_id[id] = i
          # show_xmlobj(v)
        }

        # Use the "id" attribute of EntityTypeInstance
        x_entities = @x_model.xpath("orm:Objects/orm:EntityType/orm:Instances/orm:EntityTypeInstance")
        #pp x_entities
        # x_entities.each{|v| show_xmlobj(v) }
        last_et_id = nil
        last_et = nil
        et = nil
        x_entities.each{|v|
          id = v['id']

          # Get details of the EntityType:
          xet = v.parent.parent
          et_id = xet['id']
          if (et_id != last_et_id)
            etname = xet['Name'] || ''
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
          id = v['id']
          instance = @by_id[id]
          et = @by_id[v.parent.parent['id']]
          next unless (preferred_id = et.preferred_identifier)

          # puts "Create identifying facts using #{preferred_id}"

          # Collate the referenced objects by role:
          role_instances = v.elements[0].elements.inject({}){|h, v|
              etri = @x_by_id[v['ref']]
              x_role_id = etri.parent.parent['id']
              role = @by_id[x_role_id]
              object = @by_id[object_id = etri['ref']]
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
        x_fact_roles = @x_model.xpath("orm:Facts/orm:Fact/orm:Instances/orm:FactTypeInstance/orm:RoleInstances/orm:FactTypeRoleInstance")

        last_id = nil
        last_fact_type = nil
        fact_roles = []
        x_fact_roles.each{|v|
          fact_type_id = v.parent.parent.parent.parent['id']
          id = v.parent.parent['id']
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
          x_role_instance = @x_by_id[v['ref']]
          x_role_id = x_role_instance.parent.parent['id']
          role = @by_id[x_role_id]
          throw "Role not found for instance #{x_role_id}" unless role
          instance_id = x_role_instance['ref']
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
        x_implied_facts = @x_model.xpath("orm:Facts/orm:ImpliedFact")
        pp x_implied_facts
=end
        puts "Reading Data Types (not yet)"
=begin
        x_datatypes = @x_model.xpath("orm:DataTypes/*")
        pp x_datatypes
=end
        puts "Reading Reference Mode Kinds (not yet)"
=begin
        x_refmodekinds = @x_model.xpath("orm:ReferenceModeKinds/*")
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
            }#{(n = p['Name']) ? " Name='#{n}'" : ""
            }#{(id = p['id']) ? " #{id}" : ""
            }#{(ref = p['ref']) ? " -> #{ref}" : ""
            }#{/\S/ === ((text = p.text)) ? " "+text.inspect : ""
            }"
          show_xmlobj(@x_by_id[ref], "\t#{indent}") if ref
        }
        puts "#{indent}}"
      end
    end
  end
end
