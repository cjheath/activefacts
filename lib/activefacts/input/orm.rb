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
      module Gravity
        %w{NW N NE W C E SW S SE}.each_with_index { |dir, i| const_set(dir, i) }
      end

      DataTypeMapping = {
        "FixedLengthText" => "Char",
        "VariableLengthText" => "String",
        "LargeLengthText" => "Text",
        "SignedIntegerNumeric" => "Signed Integer(32)",
        "SignedSmallIntegerNumeric" => "Signed Integer(16)",
        "SignedLargeIntegerNumeric" => "Signed Integer(64)",
        "UnsignedIntegerNumeric" => "Unsigned Integer(32)",
        "UnsignedTinyIntegerNumeric" => "Unsigned Integer(8)",
        "UnsignedSmallIntegerNumeric" => "Unsigned Integer(16)",
        "UnsignedLargeIntegerNumeric" => "Unsigned Integer(64)",
        "AutoCounterNumeric" => "Auto Counter",
        "FloatingPointNumeric" => "Real(64)",
        "SinglePrecisionFloatingPointNumeric" => " Real(32)",
        "DoublePrecisionFloatingPointNumeric" => " Real(32)",
        "DecimalNumeric" => "Decimal",
        "MoneyNumeric" => "Money",
        "FixedLengthRawData" => "Blob",
        "VariableLengthRawData" => "Blob",
        "LargeLengthRawData" => "Blob",
        "PictureRawData" => "Image",
        "OleObjectRawData" => "Blob",
        "AutoTimestampTemporal" => "Auto Time Stamp",
        "TimeTemporal" => "Time",
        "DateTemporal" => "Date",
        "DateAndTimeTemporal" => "Date Time",
        "TrueOrFalseLogical" => "Boolean",
        "YesOrNoLogical" => "Boolean",
        "RowIdOther" => "Guid",
        "ObjectIdOther" => "Guid"
      }
    RESERVED_WORDS = %w{
      and but each each either false if maybe no none not one or some that true where
    }

    private
      def self.readfile(filename, *options)
        File.open(filename) {|file|
          self.read(file, filename, *options)
        }
      end

      def self.read(file, filename = "stdin", *options)
        ORM.new(file, filename, *options).read
      end 

      def initialize(file, filename = "stdin", *options)
        @file = file
        @filename = filename
        @options = options
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
        if root.name == "ORM2" && root.namespace.prefix == "ormRoot"
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
        @vocabulary = @constellation.Vocabulary(vocabulary_name)

        # Find all elements having an "id" attribute and index them
        x_identified = @x_model.xpath(".//*[@id]")
        @x_by_id = x_identified.inject({}){|h, x|
          id = x['id']
          h[id] = x
          h
        }

        # Everything we build will be indexed here:
        @by_id = {}

        list_subtypes
        read_entity_types
        read_value_types
        read_fact_types
        read_nested_types
        read_subtypes
        read_roles
        complete_nested_types
        read_constraints
        read_instances if @options.include?("instances")
        read_diagrams if @options.include?("diagrams")
      end

      def read_entity_types
        # get and process all the entity types:
        entity_types = []
        x_entity_types = @x_model.xpath("orm:Objects/orm:EntityType")
        x_entity_types.each{|x|
          id = x['id']
          name = (x['Name'] || "").gsub(/\s+/,' ').gsub(/-/,'_').strip
          name = nil if name.size == 0
          entity_types <<
            @by_id[id] =
              entity_type =
              @constellation.EntityType(@vocabulary, name, :guid => :new)
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
        @value_type_id_read = {}
        x_value_types.each{|x|
          next if x['IsImplicitBooleanValue']
          value_types << read_value_type(x)
        }
      end

      def read_value_type x
        id = x['id']
        return if @value_type_id_read[id]   # Don't read the same value type twice
        @value_type_id_read[id] = true

        name = (x['Name'] || "").gsub(/\s+/,' ').gsub(/-/,'_').strip
        name = nil if name.size == 0

        cdt = x.xpath('orm:ConceptualDataType')[0]
        scale = cdt['Scale']
        scale = scale != "" && scale.to_i
        length = cdt['Length']
        length = length != "" && length.to_i
        length = nil if length <= 0
        base_type = @x_by_id[cdt['ref']]
        type_name = "#{base_type.name}"
        type_name.sub!(/^orm:/,'')

        type_name.sub!(/DataType\Z/,'')
        type_name = DataTypeMapping[type_name] || type_name
        if !length and type_name =~ /\(([0-9]+)\)/
          length = $1.to_i
        end
        type_name = type_name.sub(/\(([0-9]*)\)/,'')

        subtype_roles = x.xpath("orm:PlayedRoles/orm:SubtypeMetaRole")
        if !subtype_roles.empty?
          subtype_role_id = subtype_roles[0]['ref']
          subtype_role = @x_by_id[subtype_role_id]
          subtyping_fact_roles = subtype_role.parent
          supertype_id = subtyping_fact_roles.xpath("orm:SupertypeMetaRole/orm:RolePlayer")[0]['ref']
          x_supertype = @x_by_id[supertype_id]
          read_value_type x_supertype unless @value_type_id_read[supertype_id]
          supertype = @by_id[supertype_id]
          supertype_name = x_supertype['Name']
          raise "Supertype of #{name} is post-defined but recursiving processing failed" unless supertype
          raise "Supertype #{supertype_name} of #{name} is not a value type" unless supertype.kind_of? ActiveFacts::Metamodel::ValueType
          value_super_type = @constellation.ValueType(@vocabulary, supertype_name, :guid => :new)
        else
          # REVISIT: Need to handle standard types better here:
          value_super_type = type_name != name ? @constellation.ValueType(@vocabulary, type_name, :guid => :new) : nil
        end

        @by_id[id] =
          vt = @constellation.ValueType(@vocabulary, name, :guid => :new)
        vt.supertype = value_super_type
        vt.length = length if length
        vt.scale = scale if scale && scale != 0
        independent = x['IsIndependent']
        vt.is_independent = true if independent && independent == 'true'
        personal = x['IsPersonal']
        vt.pronoun = 'personal' if personal && personal == 'true'

        x_vr = x.xpath("orm:ValueRestriction/orm:ValueConstraint")
        x_vr.each{|vr|
          x_ranges = vr.xpath("orm:ValueRanges/orm:ValueRange")
          next if x_ranges.size == 0
          vt.value_constraint = @by_id[vr['id']] = @constellation.ValueConstraint(:new)
          x_ranges.each{|x_range|
            v_range = value_range(x_range)
            ar = @constellation.AllowedRange(vt.value_constraint, v_range)
          }
        }
        vt
      end

      def value_range(x_range)
        min = x_range['MinValue']
        max = x_range['MaxValue']

        strings = is_a_string(min) || is_a_string(max)
        # ValueRange takes a minimum and/or a maximum Bound, each takes value and whether inclusive
        @constellation.ValueRange(
            min && min != '' ? [[min, strings, nil], true] : nil,
            max && max != '' ? [[max, strings, nil], true] : nil
          )
      end

      def read_fact_types
        # Handle the fact types:
        facts = []
        @x_facts = @x_model.xpath("orm:Facts/orm:Fact")
        debug :orm, "Reading fact types" do
          @x_facts.each{|x|
            id = x['id']
            name = x['Name'] || x['_Name']
            name = "<unnamed>" if !name
            name = "" if !name || name.size == 0
            # Note that the new metamodel doesn't have a name for a facttype unless it's objectified
            next if x.xpath("orm:DerivationRule").size > 0

            debug :orm, "FactType #{name || id}"
            facts << @by_id[id] = fact_type = @constellation.FactType(:new)
          }
        end
      end

      def list_subtypes
        @x_subtypes = @x_model.xpath("orm:Facts/orm:SubtypeFact")
        if @document.namespaces['xmlns:oialtocdb']
          oialtocdb = @document.xpath("ormRoot:ORM2/oialtocdb:MappingCustomization")
          @x_mappings = oialtocdb.xpath(".//oialtocdb:AssimilationMappings/oialtocdb:AssimilationMapping/oialtocdb:FactType")
        else
          @x_mappings = []
        end
      end

      def read_subtypes
        # Handle the subtype fact types:
        facts = []

        debug :orm, "Reading sub-types" do
          @x_subtypes.each{|x|
            id = x['id']
            name = (x['Name'] || x['_Name'] || '').gsub(/\s+/,' ').gsub(/-/,'_').strip
            name = nil if name.size == 0
            debug :orm, "FactType #{name || id}"

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
            debug :orm, "#{subtype.name} is a subtype of #{supertype.name}"

            # We already handled ValueType subtyping:
            next if subtype.kind_of? ActiveFacts::Metamodel::ValueType or
                        supertype.kind_of? ActiveFacts::Metamodel::ValueType

            inheritance_fact = @constellation.TypeInheritance(subtype, supertype, :guid => :new)
            if x["IsPrimary"] == "true" or           # Old way
              x["PreferredIdentificationPath"] == "true"   # Newer
              debug :orm, "#{supertype.name} is primary supertype of #{subtype.name}"
              inheritance_fact.provides_identification = true
            end
            mapping = @x_mappings.detect{ |m| m['ref'] == id }
            mapping_choice = mapping ? mapping.parent['AbsorptionChoice'] : 'Absorbed'
            inheritance_fact.assimilation = mapping_choice.downcase.sub(/partition/, 'partitioned') if mapping_choice != 'Absorbed'
            facts << @by_id[id] = inheritance_fact

            # Create the new Roles so we can find constraints on them:
            subtype_role = @by_id[subtype_role_id] = @constellation.Role(inheritance_fact, 0, :object_type => subtype, :guid => :new)
            supertype_role = @by_id[supertype_role_id] = @constellation.Role(inheritance_fact, 1, :object_type => supertype, :guid => :new)

            # Create readings, so constraints can be verbalised for example:
            rs = @constellation.RoleSequence(:new)
            @constellation.RoleRef(rs, 0, :role => subtype_role)
            @constellation.RoleRef(rs, 1, :role => supertype_role)
            @constellation.Reading(inheritance_fact, 0, :role_sequence => rs, :text => "{0} is a kind of {1}")
            @constellation.Reading(inheritance_fact, 1, :role_sequence => rs, :text => "{0} is a subtype of {1}")

            rs2 = @constellation.RoleSequence(:new)
            @constellation.RoleRef(rs2, 0, :role => supertype_role)
            @constellation.RoleRef(rs2, 1, :role => subtype_role)
            n = 'aeiouh'.include?(subtype_role.object_type.name.downcase[0]) ? 1 : 0
            @constellation.Reading(inheritance_fact, 2+n, :role_sequence => rs2, :text => "{0} is a {1}")
            @constellation.Reading(inheritance_fact, 3-n, :role_sequence => rs2, :text => "{0} is an {1}")
          }
        end
      end

      def read_nested_types
        # Process NestedTypes, but ignore ones having a NestedPredicate with IsImplied="true"
        # We'll ignore the fact roles (and constraints) that implied objectifications have.
        # This happens for all ternaries and higher order facts
        @nested_types = []
        x_nested_types = @x_model.xpath("orm:Objects/orm:ObjectifiedType")
        debug :orm, "Reading objectified types" do
          x_nested_types.each{|x|
            id = x['id']
            name = (x['Name'] || "").gsub(/\s+/,' ').gsub(/-/,'_').strip
            name = nil if name.size == 0

            x_fact_type = x.xpath('orm:NestedPredicate')[0]
            is_implied = x_fact_type['IsImplied'] == "true"

            fact_id = x_fact_type['ref']
            fact_type = @by_id[fact_id]
            next if x.xpath("orm:DerivationRule").size > 0
            throw "Nested fact #{fact_id} not found" if !fact_type

            debug :orm, "NestedType #{name} is #{id}, nests #{fact_type.guid}"
            @nested_types <<
              @by_id[id] =
              nested_type = @constellation.EntityType(@vocabulary, name, :guid => :new)
            independent = x['IsIndependent']
            nested_type.is_independent = true if independent && independent == 'true' && !is_implied
            nested_type.is_implied_by_objectification = is_implied
            nested_type.fact_type = fact_type
          }
        end
      end

      def complete_nested_types
        @nested_types.each do |nested_type|
          # Create the phantom roles here. These will be used later when we create objectification steps,
          # but for now there's nothing we import from NORMA which requires objectification steps.
          # Consequently there's no need to index them against NORMA's phantom roles.
          nested_type.create_implicit_fact_types
        end
      end

      def read_roles
        debug :orm, "Reading roles and readings" do
          @x_facts.each{|x|
            id = x['id']
            next if x.xpath("orm:DerivationRule").size > 0
            fact_type = @by_id[id]
            fact_name = x['Name'] || x['_Name'] || ''
            #fact_name.gsub!(/\s/,'')
            fact_name = nil if fact_name == ''

            x_fact_roles = x.xpath('orm:FactRoles/*')
            x_reading_orders = x.xpath('orm:ReadingOrders/*')

            # Deal with FactRoles (Roles):
            debug :orm, "Reading fact roles" do
              x_fact_roles.each{|x|
                name = (x['Name'] || "").gsub(/\s+/,' ').gsub(/-/,'_').strip
                name = nil if name.size == 0

                # _IsMandatory = x['_IsMandatory']
                # _Multiplicity = x['_Multiplicity]
                id = x['id']
                rp = x.xpath('orm:RolePlayer')[0]
                raise "Invalid ORM file; fact has missing player (RolePlayer id=#{id})" unless rp
                ref = rp['ref']

                # Find the object_type that plays the role:
                object_type = @by_id[ref]

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
                  debug :orm, "Indexing unary FT role #{other_role_id} by implicit boolean role #{id}"
                  @by_id[id] = other_role

                  # The role name of the ignored role is the one that applies:
                  role_name = x['Name']
                  other_role.role_name = role_name if role_name && role_name != ''

                  @by_id.delete(ref)    # and de-index it from our list
                  next
                end
                throw "RolePlayer for '#{name}' #{ref} was not found" if !object_type

                debug :orm, "#{@vocabulary.name}, RoleName=#{x['Name'].inspect} played by object_type=#{object_type.name}"
                throw "Role is played by #{object_type.class} not ObjectType" if !(@constellation.vocabulary.object_type(:ObjectType) === object_type)

                debug :orm, "Creating role #{name} nr#{fact_type.all_role.size} of #{fact_type.guid} played by #{object_type.name}"

                role = @by_id[id] = @constellation.Role(fact_type, fact_type.all_role.size, :object_type => object_type, :guid => :new)
                role.role_name = name if name && name != object_type.name
                debug :orm, "Fact #{fact_name} (id #{fact_type.guid.object_id}) role #{x['Name']} is played by #{object_type.name}, role is #{role.object_id}"

                x_vr = x.xpath("orm:ValueRestriction/orm:RoleValueConstraint")
                x_vr.each{|vr|
                  x_ranges = vr.xpath("orm:ValueRanges/orm:ValueRange")
                  next if x_ranges.size == 0
                  role.role_value_constraint = @by_id[vr['id']] = @constellation.ValueConstraint(:new)
                  x_ranges.each{|x_range|
                    v_range = value_range(x_range)
                    ar = @constellation.AllowedRange(role.role_value_constraint, v_range)
                  }
                }

                debug :orm, "Adding Role #{role.role_name || role.object_type.name} to #{fact_type.describe}"
                #fact_type.add_role(role)
                debug :orm, "Role #{role} is #{id}"
              }
            end

            # Deal with Readings:
            debug :orm, "Reading fact readings" do
              x_reading_orders.each{|x|
                x_role_sequence = x.xpath('orm:RoleSequence/*')
                x_readings = x.xpath('orm:Readings/orm:Reading/orm:Data')

                # Build an array of the Roles needed:
                role_array = x_role_sequence.map{|x| @by_id[x['ref']] }

                debug :orm, "Reading #{x_readings.map(&:text).inspect}"
                role_sequence = get_role_sequence(role_array)

                #role_sequence.all_role_ref.each_with_index{|rr, i|
                #   # REVISIT: rr.leading_adjective = ...; Add adjectives here
                #  }

                x_readings.each_with_index{|x, i|
                  reading = @constellation.Reading(fact_type, fact_type.all_reading.size)
                  reading.role_sequence = role_sequence
                  # REVISIT: The downcase here only needs to be the initial letter of each word, but be safe:
                  reading.text = extract_adjectives(x.text, role_sequence)
                }
              }
            end
          }
        end
      end

      def extract_adjectives(text, role_sequence)
        all_role_refs = role_sequence.all_role_ref.sort_by{|rr| rr.ordinal}
        (0...all_role_refs.size).each{|i|
          role_ref = all_role_refs[i]
          role = role_ref.role

          word = '\b[A-Za-z_][A-Za-z0-9_]+\b'
          leading_adjectives_re = "#{word}-+(?: +#{word})*"
          trailing_adjectives_re = "(?:#{word} +)*-+#{word}"
          role_with_adjectives_re =
            %r| ?(#{leading_adjectives_re})? *\{#{i}\} *(#{trailing_adjectives_re})? ?|

          # A hyphenated pre-bound reading looks like this:
          # <orm:Data>{0} has pre-- bound {1}</orm:Data>

          text.gsub!(role_with_adjectives_re) {
            # REVISIT: Don't want to strip all spaces here any more:
            #puts "text=#{text.inspect}, la=#{$1.inspect}, ta=#{$2.inspect}" if $1 || $2
            la = ($1||'').gsub(/\s+/,' ') # Strip duplicate spaces
            ta = ($2||'').gsub(/\s+/,' ')
            # When we have "aaa-bbb" we want "aaa bbb"
            # When we have "aaa- bbb" we want "aaa bbb"
            # When we have "aaa-- bbb" we want "aaa-bbb"
            la = la.sub(/(-)?- ?/,'\1').strip
            ta = ta.sub(/ ?(-)?-/,'\1').strip
            #puts "Setting leading adj #{la.inspect} from #{text.inspect} for #{role_ref.role.object_type.name}" if la != ""
            # REVISIT: Dunno what's up here, but removing the "if" test makes this chuck exceptions:
            role_ref.leading_adjective = la if la != ""
            role_ref.trailing_adjective = ta if ta != ""

            #puts "Reading '#{text}' has role #{i} adjectives '#{la}' '#{ta}'" if la != "" || ta != ""

            " {#{i}} "
          }
        }
        text.sub!(/\s\s*/, ' ')   # Compress extra spaces
        text.strip!
        text.downcase!    # Check for reserved words and object type names *after* downcasing
        elided = ''
        text.gsub!(/( |-?\b[A-Za-z_][A-Za-z0-9_]*\b-?|\{\d\})|./) do |w|
          case w
          when /[A-Za-z]/
            if RESERVED_WORDS.include?(w)
              $stderr.puts "Masking reserved word '#{w}' in reading '#{text}'"
              next "_#{w}"
            elsif @constellation.ObjectType[[[@vocabulary.name], w]]
              $stderr.puts "Masking object type name '#{w}' in reading '#{text}'"
              next "_#{w}"
            elsif all_role_refs.detect{|rr| rr.role.role_name == w}
              $stderr.puts "Masking role name '#{w}' in reading '#{text}'"
              next "_#{w}"
            end
            next w
          when /\{\d\}/
            next w
          when / /
            next w
          else
            elided << w
            next ''
          end
        end
        $stderr.puts "Elided illegal characters '#{elided}' from reading #{text.inspect}" unless elided.empty?
        text
      end

      def get_role_sequence(role_array)
        # puts "Getting RoleSequence [#{role_array.map{|r| "#{r.object_type.name} (role #{r.object_id})" }*", "}]"

        # Look for an existing RoleSequence
        # REVISIT: This searches all role sequences. Perhaps we could narrow it down first instead?
        role_sequence = @constellation.RoleSequence.values.detect{|c|
          #puts "Checking RoleSequence [#{c.all_role_ref.map{|rr| rr.role.object_type.name}*", "}]"
          role_array == c.all_role_ref.sort_by{|rr| rr.ordinal}.map{|rr| rr.role }
          }
        # puts "Found matching RoleSequence!" if role_sequence
        return role_sequence if role_sequence

        # Make a new RoleSequence:
        role_sequence = @constellation.RoleSequence(:new) unless role_sequence
        role_array.each_with_index do |r, i|
          role_ref = @constellation.RoleRef(role_sequence, i)
          role_ref.role = r
        end

        role_sequence
      end

      def map_roles(x_roles, why = nil)
        role_array = x_roles.map do |x|
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
              # x_fact is the fact of which the role player is an objectification, not the fact this role belongs to
              x_fact = @x_by_id[x_nests['ref']]
            end

            # This might have been a role of an ImpliedFact, which makes it safe to ignore.
            next if 'ImpliedFact' == x_role.parent.parent.name

            next if x_role.parent.parent.xpath('orm:DerivationRule').size > 0

            # Talk about why this wasn't found - this shouldn't happen.
            if (!x_nests || !implied)
              #puts "="*60
              # We skip creating TypeInheritance implied fact types for ValueType inheritance
              return nil if x_role.name = 'orm:SubtypeMetaRole' or x_role.name = 'orm:SupertypeMetaRole'
              raise "Skipping #{why}, #{x_role.name} #{id} not found"

              if (x_nests)
                puts "Role is on #{implied ? "implied " : ""}objectification #{x_object}"
                puts "which objectifies #{x_fact}"
              end
              puts x_object.to_s
            end
          end
          role
        end
        return nil if role_array.include?(nil)

        get_role_sequence(role_array)
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
        debug :orm, "Scanning mandatory constraints" do
          x_mandatory_constraints.each{|x|
            name = x["Name"] || ''
            name = nil if name.size == 0

            # As of Feb 2008, all NORMA ValueTypes have an implied mandatory constraint.
            next if x.xpath("orm:ImpliedByObjectType").size > 0

            x_roles = x.xpath("orm:RoleSequence/orm:Role")
            role_sequence = map_roles(x_roles, "mandatory constraint #{name}")
            next if !role_sequence

            debug :orm, "New MC #{x['Name']} over #{role_sequence.describe}"
            @mandatory_constraints_by_rs[role_sequence] = x
            @mandatory_constraint_rs_by_id[x['id']] = role_sequence
          }
        end
      end

      # Mandatory constraints that didn't get merged with an exclusion constraint or a uniqueness constraint are simple mandatories
      def read_residual_mandatory_constraints
        debug :orm, "Processing non-absorbed mandatory constraints" do
          @mandatory_constraints_by_rs.each { |role_sequence, x|
            id = x['id']
            # Create a simply-mandatory PresenceConstraint for each mandatory constraint
            name = x["Name"] || ''
            name = nil if name.size == 0
            #puts "Residual Mandatory #{name}: #{role_sequence.to_s}"

            if (players = role_sequence.all_role_ref.map{|rr| rr.role.object_type}).uniq.size > 1
              join_over, = *ActiveFacts::Metamodel.plays_over(role_sequence.all_role_ref.map{|rr| rr.role}, :proximate)
              raise "Mandatory join constraint #{name} has incompatible players #{players.map{|o| o.name}.inspect}" unless join_over
              if players.detect{|p| p != join_over}
                debug :query, "subtyping step simple mandatory constraint #{name} over #{join_over.name}"
                players.each_with_index do |player, i|
                  next if player != join_over
                  # REVISIT: We don't need to make a subtyping step here (from join_over to player)
                end
              end
            end

            pc = @constellation.PresenceConstraint(:new)
            pc.vocabulary = @vocabulary
            pc.name = name
            pc.role_sequence = role_sequence
            pc.is_mandatory = true
            pc.min_frequency = 1 
            pc.max_frequency = nil
            pc.is_preferred_identifier = false

            (@constraints_by_rs[role_sequence] ||= []) << pc
            @by_id[id] = pc
          }
        end
      end

      def read_uniqueness_constraints
        x_uniqueness_constraints = @x_model.xpath("orm:Constraints/orm:UniquenessConstraint")
        debug :orm, "Reading uniqueness constraints" do
          x_uniqueness_constraints.each{|x|
            name = x["Name"] || ''
            name = nil if name.size == 0
            uc_id = x["id"]
            x_pi = x.xpath("orm:PreferredIdentifierFor")[0]
            pi = x_pi ? @by_id[eref = x_pi['ref']] : nil

            # Skip uniqueness constraints on implied object_types
            next if x_pi && !pi

            # Get the RoleSequence:
            x_roles = x.xpath("orm:RoleSequence/orm:Role")
            next if x_roles.size == 0
            role_sequence = map_roles(x_roles, "uniqueness constraint #{name}")
            next if !role_sequence
            #puts "uc: #{role_sequence.all_role_ref.map{|rr|rr.role.fact_type.default_reading}*', '}"

            # Check for a query
            if (fact_types = role_sequence.all_role_ref.map{|rr| rr.role.fact_type}).uniq.size > 1
              join_over, = *ActiveFacts::Metamodel.plays_over(role_sequence.all_role_ref.map{|rr| rr.role}, :counterpart)

              players = role_sequence.all_role_ref.map{|rr| rr.role.object_type.name}.uniq
              raise "Uniqueness join constraint #{name} has incompatible players #{players.inspect}" unless join_over
              subtyping = players.size > 1 ? 'subtyping ' : ''
              # REVISIT: Create the Query, the Variable for join_over, and steps from each role_ref to join_over
              debug :query, "#{subtyping}join uniqueness constraint over #{join_over.name} in #{fact_types.map(&:default_reading)*', '}"
            end

            # There is an implicit uniqueness constraint when any object plays a unary. Skip it.
            if (x_roles.size == 1 &&
                (id = x_roles[0]['ref']) &&
                (x_role = @x_by_id[id]) &&
                (nodes = x_role.parent.elements).size == 2 &&
                (sibling = nodes[1]) &&
                (ib_id = sibling.elements[0]['ref']) &&
                (ib = @x_by_id[ib_id]) &&
                ib['IsImplicitBooleanValue'])
              unary_identifier = true
            end

            mc_id = nil

            if (mc = @mandatory_constraints_by_rs[role_sequence])
              # Remove absorbed mandatory constraints, leaving residual ones.
              debug :orm, "Absorbing MC #{mc['Name']} over #{role_sequence.describe}"
              @mandatory_constraints_by_rs.delete(role_sequence)
              mc_id = mc['id']
              @mandatory_constraint_rs_by_id.delete(mc['id'])
            elsif (fts = role_sequence.all_role_ref.map{|rr| rr.role.fact_type}.uniq).size == 1 and
              fts[0].entity_type
              # this uniqueness constraint is an internal UC on an objectified fact type,
              # so the covered roles are always mandatory (wrt the OFT)
              # That is, the phantom roles are mandatory, even if the visible roles are not.
              mc = true
            else
              debug :orm, "No MC to absorb over #{role_sequence.describe}"
            end

            # A TypeInheritance fact type has a uniqueness constraint on each role.
            # If this UC is on the supertype and identifies the subtype, it's preferred:
            is_supertype_constraint =
              (rr = role_sequence.all_role_ref.single) &&
              (role = rr.role) &&
              (fact_type = role.fact_type) &&
              fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance) &&
              role.object_type == fact_type.supertype &&
              fact_type.provides_identification

            pc = @constellation.PresenceConstraint(:new)
            pc.vocabulary = @vocabulary
            pc.name = name
            pc.role_sequence = role_sequence
            pc.is_mandatory = true if mc
            pc.min_frequency = mc ? 1 : 0
            pc.max_frequency = 1 
            pc.is_preferred_identifier = true if pi || unary_identifier || is_supertype_constraint
            debug :orm, "#{name} covers #{role_sequence.describe} has min=#{pc.min_frequency}, max=1, preferred=#{pc.is_preferred_identifier.inspect}"

            debug :orm, role_sequence.all_role_ref.to_a[0].role.fact_type.describe + " is subject to " + pc.describe if role_sequence.all_role_ref.all?{|r| r.role.fact_type.is_a? ActiveFacts::Metamodel::TypeInheritance }

            (@constraints_by_rs[role_sequence] ||= []) << pc
            @by_id[uc_id] = pc
            @by_id[mc_id] = pc if mc_id
          }
        end
      end

      def subtype_step(query, ti)
        subtype_node = query.all_variable.detect{|jn| jn.object_type == ti.subtype } ||
          @constellation.Variable(query, query.all_variable.size, :object_type => ti.subtype)
        supertype_node = query.all_variable.detect{|jn| jn.object_type == ti.supertype } ||
          @constellation.Variable(query, query.all_variable.size, :object_type => ti.supertype)
        rs = @constellation.RoleSequence(:new)
        @constellation.RoleRef(rs, 0, :role => ti.subtype_role)
        sub_play = @constellation.Play(subtype_node, ti.subtype_role)
        @constellation.RoleRef(rs, 1, :role => ti.supertype_role)
        sup_play = @constellation.Play(supertype_node, ti.supertype_role)
        step = @constellation.Step(sub_play, sup_play, :fact_type => ti)
        debug :query, "New subtyping step #{step.describe}"
        step
      end

      # Make as many steps as it takes to get from subtype to supertype
      def subtype_steps(query, subtype, supertype)
        primary_ti = nil
        other_ti = nil
        subtype.all_type_inheritance_as_subtype.each do |ti|
          next unless ti.supertype.supertypes_transitive.include? supertype
          if ti.provides_identification
            primary_ti ||= ti
          else
            other_ti ||= ti
          end
        end
        ti = primary_ti || other_ti
        # Make supertype steps first:
        (ti.supertype == supertype ? [] : subtype_steps(query, ti.supertype, supertype)) +
          [subtype_step(query, ti)]
      end

      # Equality and subset join constraints involve two or more role sequences,
      # and the respective roles from each sequence must be compatible,
      # Compatibility might involve subtyping steps but not objectification steps
      # to the respective end-point (constrained object type).
      # Also, all roles in each sequence constitute a join over a single
      # object type, which might involve subtyping or objectification steps.
      #
      def make_queries(constraint_type, name, role_sequences)
        begin
          # Get the object types constrained for each position in the role sequences.
          # Supertyping steps may be needed to reach them.
          end_points = []   # An array of the common supertype for matching role_refs across the sequences
          end_steps = []    # An array of booleans indicating whether any role_sequence requires subtyping steps
          role_sequences[0].all_role_ref.size.times do |i|
            role_refs = role_sequences.map{|rs| rs.all_role_ref.detect{|rr| rr.ordinal == i}}
            if (fact_types = role_refs.map{|rr| rr.role.fact_type}).uniq.size == 1
              # $stderr.puts(role_sequences.map{|rs| rs.all_role_ref.map{|rr| rr.role.fact_type.describe(rr.role)}}.inspect)
              raise "In #{constraint_type} #{name} role sequence #{i}, there is a faulty join involving just 1 fact type: '#{fact_types[0].default_reading}'"
            end
            if (players = role_refs.map{|rr| rr.role.object_type}).uniq.size == 1
              end_point = players[0]
              end_steps[i] = false
            else
              # Can the players be joined using subtyping steps?
              common_supertypes = players[1..-1].
                inject(players[0].supertypes_transitive) do |remaining, player|
                  remaining & player.supertypes_transitive
                end
              end_point = common_supertypes[0]

              raise "constrained roles of #{constraint_type} #{name} are incompatible (#{players.map(&:name)*', '})" if common_supertypes.size == 0
              end_steps[i] = true
            end
            end_points[i] = end_point
          end

          # For each role_sequence, find the object type over which the join is implied (nil if no join)
          sequence_join_over = []
          if role_sequences[0].all_role_ref.size > 1    # There are queries within each sequence.
            sequence_join_over = []
            sequence_joined_roles = []
            role_sequences.map do |rs|
              join_over, joined_roles = *ActiveFacts::Metamodel.plays_over(rs.all_role_ref.map{|rr| rr.role})
              sequence_join_over << join_over
              sequence_joined_roles << joined_roles
            end
          end

          # If there are no queries, we can drop out here.
          if sequence_join_over.compact.empty? && !end_steps.detect{|e| true}
            return true
          end

          debug :query, "#{constraint_type} join constraint #{name} over #{role_sequences.map{|rs|rs.describe}*', '}"

          query = nil
          debug :query, "#{constraint_type} join constraint #{name} constrains #{
              end_points.zip(end_steps).map{|(p,j)| (p ? p.name : 'NULL')+(j ? ' & subtypes':'')}*', '
            }#{
            if role_sequences[0].all_role_ref.size > 1
              ", joined over #{
                sequence_join_over.zip(sequence_joined_roles).map{|o, roles|
                  (o ? o.name : '(none)') +
                    (roles ? " to (#{roles.map{|role| role ? role.fact_type.default_reading : 'null'}*','})" : '')
                }*', '}"
            else
              ''
            end
          }" do

            # There may be one query per role sequence:
            role_sequences.zip(sequence_join_over||[], sequence_joined_roles||[]).map do |role_sequence, join_over, joined_roles|
              # Skip if there's no query here (sequence join nor end-point subset join)
              role_refs = role_sequence.all_role_ref_in_order
              if !join_over and !role_refs.detect{|rr| rr.role.object_type != end_points[rr.ordinal]}
                # No sequence join nor end_point join here
                next
              end

              # A RoleSequence for the actual query end-points
              replacement_rs = @constellation.RoleSequence(:new)

              query = @constellation.Query(:new)
              variable = nil
              query_role = nil
              role_refs.zip(joined_roles||[]).each_with_index do |(role_ref, joined_role), i|

                # Each role_ref is to an object joined via joined_role to variable (or which will be the variable)

                # Create a variable for the actual end-point (supertype of the constrained roles)
                end_point = end_points[i]
                unless end_point
                  raise "In #{constraint_type} #{name}, there is a faulty or non-translated query"
                end
                debug :query, "Variable #{query.all_variable.size} is for #{end_point.name}"
                end_node = @constellation.Variable(query, query.all_variable.size, :object_type => end_point)

                # We're going to rewrite the constraint to constrain the supertype roles, but assume they're the same:
                role_node = end_node
                end_role = role_ref.role

                # Create subtyping steps at the end-point, if needed:
                projecting_play = nil
                constrained_play = nil
                if (subtype = role_ref.role.object_type) != end_point
                  debug :query, "Making subtyping steps from #{subtype.name} to #{end_point.name}" do
                    # There may be more than one supertyping level. Make the steps:
                    subtyping_steps = subtype_steps(query, subtype, end_point)
                    step = subtyping_steps[0]
                    constrained_play = subtyping_steps[-1].input_play

                    # Replace the constrained role and node with the supertype ones:
                    end_node = query.all_variable.detect{|jn| jn.object_type == end_point }
                    projecting_play = step.output_play
                    end_role = step.fact_type.all_role.detect{|r| r.object_type == end_point }
                    role_node = query.all_variable.detect{|jn| jn.object_type == role_ref.role.object_type }
                  end
                end

                raise "Internal error in #{constraint_type} #{name}: making illegal reference to variable, end role mismatch" if end_role.object_type != end_node.object_type
                rr = @constellation.RoleRef(replacement_rs, replacement_rs.all_role_ref.size, :role => end_role)
                projecting_play ||= (constrained_play = @constellation.Play(end_node, end_role))
                projecting_play.role_ref = rr   # Project this RoleRef
                # projecting_play.variable.projection = rr.role   # REVISIT: The variable should project a role, not the Play a RoleRef

                if join_over
                  if !variable     # Create the Variable when processing the first role
                    debug :query, "Variable #{query.all_variable.size} is over #{join_over.name}"
                    variable = @constellation.Variable(query, query.all_variable.size, :object_type => join_over)
                  end
                  debug :query, "Making step from #{end_point.name} to #{join_over.name}" do
                    rs = @constellation.RoleSequence(:new)
                    # Detect the fact type over which we're stepping (may involve objectification)
                    raise "Internal error in #{constraint_type} #{name}: making illegal reference to variable, object type mismatch" if role_ref.role.object_type != role_node.object_type
                    @constellation.RoleRef(rs, 0, :role => role_ref.role)
                    role_play = @constellation.Play(role_node, role_ref.role)
                    raise "Internal error in #{constraint_type} #{name}: making illegal reference to variable, joined_role mismatch" if joined_role.object_type != variable.object_type
                    @constellation.RoleRef(rs, 1, :role => joined_role)
                    join_play = @constellation.Play(variable, joined_role)

                    step = @constellation.Step(role_play, join_play, :fact_type => joined_role.fact_type)
                    debug :query, "New step #{step.describe}"
                  end
                else
                  debug :query, "Need step for non-join_over role #{end_point.name} #{role_ref.describe} in #{role_ref.role.fact_type.default_reading}"
                  if (roles = role_ref.role.fact_type.all_role.to_a).size > 1
                    # Here we have an end join (step already created) but no sequence join
                    if variable
                      raise "Internal error in #{constraint_type} #{name}: making illegal step" if role_ref.role.object_type != role_node.object_type
                      join_play = @constellation.Play(variable, query_role)
                      role_play = @constellation.Play(role_node, role_ref.role)
                      step = @constellation.Step(join_play, role_play, :fact_type => role_ref.role.fact_type)
                      roles -= [query_role, role_ref.role]
                      roles.each do |incidental_role|
                        jn = @constellation.Variable(query, query.all_variable.size, :object_type => incidental_role.object_type)
                        play = @constellation.Play(jn, incidental_role, :step => step)
                      end
                    else
                      if role_sequence.all_role_ref.size > 1
                        variable = role_node
                        query_role = role_ref.role
                      else
                        # There's no query in this role sequence, so we'd drop off the bottom without doing the right things. Why?
                        # Without this case, Supervision.orm omits "that runs Company" from the exclusion constraint, and I'm not sure why.
                        # I think the "then" code causes it to drop out the bottom without making the step (which is otherwise made in every case, see CompanyDirectorEmployee for example)
                        role_play = @constellation.Play(role_node, role_ref.role)
                        step = nil
                        role_ref.role.fact_type.all_role.each do |role|
                          next if role == role_play.role
                          next if role_sequence.all_role_ref.detect{|rr| rr.role == role}
                          jn = @constellation.Variable(query, query.all_variable.size, :object_type => role.object_type)
                          play = @constellation.Play(jn, role)
                          if step
                            play.step = step  # Incidental role
                          else
                            step = @constellation.Step(role_play, play, :fact_type => role_ref.role.fact_type)
                          end
                        end
                      end
                    end
                  else
                    # Unary fact type, make a Step from and to the constrained_play
                    play = @constellation.Play(constrained_play.variable, role_ref.role)
                    step = @constellation.Step(play, play, :fact_type => role_ref.role.fact_type)
                  end
                end
              end

              # Thoroughly check that this is a valid query
              query.validate
              debug :query, "Query has projected nodes #{replacement_rs.describe}"

              # Constrain the replacement role sequence, which has the attached query:
              role_sequences[role_sequences.index(role_sequence)] = replacement_rs
            end
            return true
          end
        rescue => e
          debugger if debug :debug
          $stderr.puts "// #{e.to_s}: #{e.backtrace[0]}"
          return false
        end

      end

      def read_exclusion_constraints
        x_exclusion_constraints = @x_model.xpath("orm:Constraints/orm:ExclusionConstraint")
        debug :orm, "Reading #{x_exclusion_constraints.size} exclusion constraints" do
          x_exclusion_constraints.each{|x|
            id = x['id']
            name = x["Name"] || ''
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

            next if role_sequences.compact.size != role_sequences.size  # Role sequence missing; includes a derived fact type role

            next unless make_queries('exclusion', name+(x_mandatory ? '/'+x_mandatory['Name'] : ''), role_sequences)

            ec = @constellation.SetExclusionConstraint(:new)
            ec.vocabulary = @vocabulary
            ec.name = name
            # ec.enforcement = 
            role_sequences.each_with_index do |rs, i|
              @constellation.SetComparisonRoles(ec, i, :role_sequence => rs)
            end
            ec.is_mandatory = true if x_mandatory
            @by_id[id] = ec
            @by_id[mc_id] = ec if mc_id
          }
        end
      end

      def read_equality_constraints
        x_equality_constraints = @x_model.xpath("orm:Constraints/orm:EqualityConstraint")
        debug :orm, "Reading equality constraints" do
          x_equality_constraints.each{|x|
            id = x['id']
            name = x["Name"] || ''
            name = nil if name.size == 0
            role_sequences = 
              x.xpath("orm:RoleSequences/orm:RoleSequence").map{|x_rs|
                  x_role_refs = x_rs.xpath("orm:Role")
                  map_roles(
                    x_role_refs , # .map{|xr| @x_by_id[xr['ref']] },
                    "equality constraint #{name}"
                  )
                }

            # Role sequence missing; includes a derived fact type role
            next if role_sequences.compact.size != role_sequences.size

            next unless make_queries('equality', name, role_sequences)

            ec = @constellation.SetEqualityConstraint(:new)
            ec.vocabulary = @vocabulary
            ec.name = name
            # ec.enforcement = 
            role_sequences.each_with_index do |rs, i|
              @constellation.SetComparisonRoles(ec, i, :role_sequence => rs)
            end
            @by_id[id] = ec
          }
        end
      end

      def read_subset_constraints
        x_subset_constraints = @x_model.xpath("orm:Constraints/orm:SubsetConstraint")
        debug :orm, "Reading subset constraints" do
          x_subset_constraints.each{|x|
            id = x['id']
            name = x["Name"] || ''
            name = nil if name.size == 0
            role_sequences = 
              x.xpath("orm:RoleSequences/orm:RoleSequence").map{|x_rs|
                  x_role_refs = x_rs.xpath("orm:Role")
                  map_roles(
                    x_role_refs , # .map{|xr| @x_by_id[xr['ref']] },
                    "equality constraint #{name}"
                  )
                }
            next if role_sequences.compact.size != role_sequences.size  # Role sequence missing; includes a derived fact type role
            next unless make_queries('subset', name, role_sequences)

            ec = @constellation.SubsetConstraint(:new)
            ec.vocabulary = @vocabulary
            ec.name = name
            # ec.enforcement = 
            ec.subset_role_sequence = role_sequences[0]
            ec.superset_role_sequence = role_sequences[1]
            @by_id[id] = ec
          }
        end
      end

      def read_ring_constraints
        x_ring_constraints = @x_model.xpath("orm:Constraints/orm:RingConstraint")
        debug :orm, "Reading ring constraints" do
          x_ring_constraints.each{|x|
            id = x['id']
            name = x["Name"] || ''
            name = nil if name.size == 0
            ring_type = x["Type"]

            from, to = *x.xpath("orm:RoleSequence/orm:Role").
              map do |xr|
                @by_id[xr['ref']]
              end
            next unless from && to  # Roles missing; covers a derived fact type
            if from.object_type != to.object_type
              join_over, = *ActiveFacts::Metamodel.plays_over([from, to], :counterpart)
              raise "Ring constraint has incompatible players #{from.object_type.name}, #{to.object_type.name}" if !join_over
              debug :query, "join ring constraint over #{join_over.name}"
            end
            rc = @constellation.RingConstraint(:new)
            rc.vocabulary = @vocabulary
            rc.name = name
            # rc.enforcement = 
            rc.role = from
            rc.other_role = to
            rc.ring_type = ring_type.gsub(/PurelyReflexive/,'Reflexive')
            @by_id[id] = rc
          }
        end
      end

      def read_frequency_constraints
        x_frequency_constraints = @x_model.xpath("orm:Constraints/orm:FrequencyConstraint")
        debug :orm, "Reading frequency constraints" do
          x_frequency_constraints.each do |x_frequency_constraint|
            id = x_frequency_constraint['id']
            min_frequency = x_frequency_constraint["MinFrequency"].to_i
            min_frequency = nil if min_frequency == 0
            max_frequency = x_frequency_constraint["MaxFrequency"].to_i
            max_frequency = nil if max_frequency == 0
            x_roles = x_frequency_constraint.xpath("orm:RoleSequence/orm:Role")
            role = @by_id[x_roles[0]["ref"]]
            role_sequence = @constellation.RoleSequence(:new)
            role_ref = @constellation.RoleRef(role_sequence, 0, :role => role)
            next unless role  # Role missing; belongs to a derived fact type
            debug :orm, "FrequencyConstraint(min #{min_frequency.inspect} max #{max_frequency.inspect} over #{role.fact_type.describe(role)} #{id} role ref = #{x_roles[0]["ref"]}"
            @by_id[id] = @constellation.PresenceConstraint(
                :new,
                :vocabulary => @vocabulary,
                :name => name = x_frequency_constraint["Name"] || '',
                :role_sequence => role_sequence,
                :is_mandatory => false,
                :min_frequency => min_frequency,
                :max_frequency => max_frequency,
                :is_preferred_identifier => false
              )
          end
        end
      end

      def read_instances
        debug :orm, "Reading sample data" do
          population = @constellation.Population(@vocabulary, "sample", :guid => :new)

          # Value instances first, then entities then facts:

          x_values = @x_model.xpath("orm:Objects/orm:ValueType/orm:Instances/orm:ValueTypeInstance/orm:Value")
          #pp x_values.map{|v| [ v.parent['id'], v.text ] }
          debug :orm, "Reading sample values" do
            x_values.each{|v|
              id = v.parent['id']
              # Get details of the ValueType:
              xvt = v.parent.parent.parent
              vt_id = xvt['id']
              vtname = xvt['Name'] || ''
              #vtname.gsub!(/\s/,'')
              vtname = nil if vtname.size == 0
              vt = @by_id[vt_id]
              throw "ValueType #{vtname} not found" unless vt

              i = @constellation.Instance(:new, :population => population, :object_type => vt, :value => [v.text, is_a_string(v.text), nil])
              @by_id[id] = i
              # show_xmlobj(v)
            }
          end

          # Use the "id" attribute of EntityTypeInstance
          x_entities = @x_model.xpath("orm:Objects/orm:EntityType/orm:Instances/orm:EntityTypeInstance")
          #pp x_entities
          # x_entities.each{|v| show_xmlobj(v) }
          last_et_id = nil
          last_et = nil
          et = nil
          debug :orm, "Reading sample entities" do
            x_entities.each{|v|
              id = v['id']

              # Get details of the EntityType:
              xet = v.parent.parent
              et_id = xet['id']
              if (et_id != last_et_id)
                etname = xet['Name'] || ''
                #etname.gsub!(/\s/,'')
                etname = nil if etname.size == 0
                last_et = et = @by_id[et_id]
                last_et_id = et_id
                throw "EntityType #{etname} not found" unless et
              end

              instance = @constellation.Instance(:new, :population => population, :object_type => et, :value => nil)
              @by_id[id] = instance
              debug :orm, "Made new EntityType #{etname}"
            }
          end

          # The EntityType instances have implicit facts for the PI facts.
          # We must create implicit PI facts after all the instances.
          entity_count = 0
          pi_fact_count = 0
          debug :orm, "Creating identifying facts for entities" do
            x_entities.each do |v|
              id = v['id']
              instance = @by_id[id]
              et = @by_id[v.parent.parent['id']]
              next unless (preferred_id = et.preferred_identifier)

              debug :orm, "Create identifying facts using #{preferred_id}"

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
              identifying_fact_types =
                preferred_id.role_sequence.all_role_ref.map { |rr| rr.role.fact_type }.uniq
              identifying_fact_types.
                each do |ft|
                  debug :orm, "For FactType #{ft}" do
                    fact = @constellation.Fact(:new, :population => population, :fact_type => ft)
                    fact_roles = ft.all_role.map do |role|
                      if role.object_type == et
                        object = instance
                      else
                        object = role_instances[role]
                        debug :orm, "instance for role #{role} is #{object}"
                      end
                      @constellation.RoleValue(:instance => object, :population => population, :fact => fact, :role => role)
                    end
                  end
                  pi_fact_count += 1
                end

              entity_count += 1
            end
          end
          debug :orm, "Created #{pi_fact_count} facts to identify #{entity_count} entities"

          # Use the "ref" attribute of FactTypeRoleInstance:
          x_fact_roles = @x_model.xpath("orm:Facts/orm:Fact/orm:Instances/orm:FactTypeInstance/orm:RoleInstances/orm:FactTypeRoleInstance")

          last_id = nil
          fact = nil
          fact_roles = []
          debug :orm, "Reading sample facts" do
            x_fact_roles.each do |v|
              fact_type_id = v.parent.parent.parent.parent['id']
              id = v.parent.parent['id']
              fact_type = @by_id[fact_type_id]
              throw "Fact type #{fact_type_id} not found" unless fact_type

              # Create initial and subsequent Fact objects:
              fact = @constellation.Fact(:new, :population => population, :fact_type => fact_type) unless fact && last_id == id
              last_id = id

              # REVISIT: This doesn't handle instances of objectified fact types (where a RoleValue.instance objectifies Fact)

              x_role_instance = @x_by_id[v['ref']]
              x_role_id = x_role_instance.parent.parent['id']
              role = @by_id[x_role_id]
              throw "Role not found for instance #{x_role_id}" unless role
              instance_id = x_role_instance['ref']
              instance = @by_id[instance_id]
              throw "Instance not found for FactRole #{instance_id}" unless instance
              @constellation.RoleValue(:instance => instance, :population => population, :fact => fact, :role => role)
            end
          end

        end
      end

      def read_diagrams
        x_diagrams = @document.root.xpath("ormDiagram:ORMDiagram")
        debug :orm, "Reading diagrams" do
          x_diagrams.each do |x|
            name = (x["Name"] || '').strip
            diagram = @constellation.Diagram(@vocabulary, name)
            debug :diagram, "Starting to read diagram #{name}"
            shapes = x.xpath("ormDiagram:Shapes/*")
            debug :orm, "Reading shapes" do
              shapes.map do |x_shape|
                x_subject = x_shape.xpath("ormDiagram:Subject")[0]
                subject = @by_id[x_subject["ref"]]
                is_expanded = v = x_shape['IsExpanded'] and v == 'true'
                bounds = x_shape['AbsoluteBounds']
                case shape_type = x_shape.name
                when 'FactTypeShape'
                  if subject
                    read_fact_type_shape diagram, x_shape, is_expanded, bounds, subject
                  # else REVISIT: probably a derived fact type
                  end
                when 'ExternalConstraintShape', 'FrequencyConstraintShape'
                  # REVISIT: The offset might depend on the constraint type. This is right for subset and other round ones.
                  position = convert_position(bounds, Gravity::C)
                  shape = @constellation.ConstraintShape(
                      :new, :diagram => diagram, :position => position, :is_expanded => is_expanded,
                      :constraint => subject
                    )
                when 'RingConstraintShape'
                  # REVISIT: The offset might depend on the ring constraint type. This is right for basic round ones.
                  position = convert_position(bounds, Gravity::C)
                  shape = @constellation.RingConstraintShape(
                      :new, :diagram => diagram, :position => position, :is_expanded => is_expanded,
                      :constraint => subject
                    )
                  shape.fact_type = subject.role.fact_type
                when 'ModelNoteShape'
                  # REVISIT: Add model notes
                when 'ObjectTypeShape'
                  position = convert_position(bounds, Gravity::C)
                  # $stderr.puts "#{subject.name}: bounds=#{bounds} -> position = (#{position.x}, #{position.y})"
                  shape = @constellation.ObjectTypeShape(
                      :new, :diagram => diagram, :position => position, :is_expanded => is_expanded,
                      :object_type => subject,
                      :position => position
                    )
                else
                  raise "Unknown shape #{x_shape.name}"
                end
              end
            end
          end
        end
      end

      def read_fact_type_shape diagram, x_shape, is_expanded, bounds, fact_type
        display_role_names_setting = v = x_shape["DisplayRoleNames"] and
          case v
          when 'Off'; 'false'
          when 'On'; 'true'
          else nil
          end
        rotation_setting = v = x_shape['DisplayOrientation'] and
          case v
          when 'VerticalRotatedLeft'; 'left'
          when 'VerticalRotatedRight'; 'right'
          else nil
          end

        # Position of a fact type is the centre of the row of role boxes
        offs_x = 11
        offs_y = -12
        if fact_type.entity_type
          offs_x -= 12
          offs_y -= 9 if !fact_type.entity_type.is_implied_by_objectification
        end

        position = convert_position(bounds, Gravity::S, offs_x, offs_y)

        # $stderr.puts "#{fact_type.describe}: bounds=#{bounds} -> position = (#{position.x}, #{position.y})"

        debug :orm, "REVISIT: Can't place rotated fact type correctly on diagram yet" if rotation_setting

        debug :orm, "fact type at #{position.x},#{position.y} has display_role_names_setting=#{display_role_names_setting.inspect}, rotation_setting=#{rotation_setting.inspect}"
        shape = @constellation.FactTypeShape(
            :new,
            :diagram => diagram,
            :position => position,
            :is_expanded => is_expanded,
            :display_role_names_setting => display_role_names_setting,
            :rotation_setting => rotation_setting,
            :fact_type => fact_type
          )
        # Create RoleDisplay objects if necessary
        x_role_display = x_shape.xpath("ormDiagram:RoleDisplayOrder/ormDiagram:Role")
        # print "Fact type '#{fact_type.preferred_reading.expand}' (#{fact_type.all_role.map{|r|r.object_type.name}*' '})"
        if x_role_display.size > 0
          debug :orm, " has roleDisplay (#{x_role_display.map{|rd| @by_id[rd['ref']].object_type.name}*','})'"
          x_role_display.each_with_index do |rd, ordinal|
            role_display = @constellation.RoleDisplay(shape, ordinal, :role => @by_id[rd['ref']])
          end
        else
          # Decide whether to create all RoleDisplay objects for this fact type, which is in role order
          # Omitting this here might lead to incomplete RoleDisplay sequences,
          # because each RoleNameShape or ValueConstraintShape creates just one.
          debug :orm, " has no roleDisplay"
        end

        relative_shapes = x_shape.xpath('ormDiagram:RelativeShapes/*')
        relative_shapes.each do |xr_shape|
          position = convert_position(xr_shape['AbsoluteBounds'])
          case xr_shape.name
          when 'ObjectifiedFactTypeNameShape'
            @constellation.ObjectifiedFactTypeNameShape(shape, :guid => :new, :diagram => diagram, :position => position, :is_expanded => false)
          when 'ReadingShape'
            @constellation.ReadingShape(shape, :guid => :new, :fact_type_shape=>shape, :diagram => diagram, :position => position, :is_expanded => false, :reading => fact_type.preferred_reading)
          when 'RoleNameShape'
            role = @by_id[xr_shape.xpath("ormDiagram:Subject")[0]['ref']]
            role_display = role_display_for_role(shape, x_role_display, role)
            debug :orm, "Fact type '#{fact_type.preferred_reading.expand}' has #{xr_shape.name}"
            @constellation.RoleNameShape(
              :new, :diagram => diagram, :position => position, :is_expanded => false,
              :role_display => role_display
            )
          when 'ValueConstraintShape'
            vc_subject_id = xr_shape.xpath("ormDiagram:Subject")[0]['ref']
            constraint = @by_id[vc_subject_id]
            debug :orm, "Fact type '#{fact_type.preferred_reading.expand}' has #{xr_shape.name} for #{constraint.inspect}"

            role_display = role_display_for_role(shape, x_role_display, constraint.role)
            debug :orm, "ValueConstraintShape is on #{role_display.ordinal}'th role (by #{x_role_display.size > 0 ? 'role_display' : 'fact roles'})"
            @constellation.ValueConstraintShape(
              :new, :diagram => diagram, :position => position, :is_expanded => false,
              :constraint => constraint,
              :object_type_shape => nil,  # This constraint is relative to a Fact Type, so must be on a role
              :role_display => role_display
            )
          else raise "Unknown relative shape #{xr_shape.name}"
          end
        end
      end

      # Find or create the RoleDisplay for this role in this fact_type_shape, given (possibly empty) x_role_display nodes:
      def role_display_for_role(fact_type_shape, x_role_display, role)
        if x_role_display.size == 0
          # There's no x_role_display, which means the roles are in displayed 
          # the same order as in the fact type. However, we need a RoleDisplay
          # to attach a ReadingShape or ValueConstraintShape, so make them all.
          fact_type_shape.fact_type.all_role.each{|r| @constellation.RoleDisplay(fact_type_shape, r.ordinal, :role => r) }
          role_ordinal = fact_type_shape.fact_type.all_role_in_order.index(role)
        else
          role_ordinal = x_role_display.map{|rd| @by_id[rd['ref']]}.index(role)
        end
        role_display = @constellation.RoleDisplay(fact_type_shape, role_ordinal, :role => role)
      end

      DIAGRAM_SCALE = 96*1.5
      def convert_position(bounds, gravity = Gravity::C, xoffs = 0, yoffs = 0)
        return nil unless bounds
        # Bounds is top, left, width, height in inches
        bf = bounds.split(/, /).map{|b|b.to_f}
        sizefrax = [
          [0, 0], [1, 0], [2, 0],
          [0, 1], [1, 1], [2, 2],
          [0, 2], [1, 2], [2, 2],
        ]

        x = (DIAGRAM_SCALE * (bf[0]+bf[2]*sizefrax[gravity][0]/2)).round + xoffs
        y = (DIAGRAM_SCALE * (bf[1]+bf[3]*sizefrax[gravity][1]/2)).round + yoffs
        @constellation.Position(x, y)
      end

      # Detect numeric data and denote it as a string:
      def is_a_string(value)
        value =~ /[^ \d.]/
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
