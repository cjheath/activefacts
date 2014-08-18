#
#       ActiveFacts Generators.
#       Generate a Scala module for the ActiveFacts API from an ActiveFacts vocabulary.
#
# Copyright (c) 2013 Clifford Heath. Read the LICENSE file.
#
require 'activefacts'
require 'activefacts/vocabulary'
require 'activefacts/generate/helpers/oo'
require 'activefacts/mapping/rails'

class String
  class Words
    def initialize words
      @words = words
    end

    def to_s
      titlecase
    end

    def titlecase
      @words.map{|w| w.downcase.sub(/^[[:alpha:]]/) { |i| i.upcase }}.join('')
    end

    def camelcase
      titlecase.sub(/^[[:upper:]]/) { |i| i.downcase }
    end

    def snakecase
      @words.map{|w| w.downcase}.join('_')
    end
  end

  def words
    Words.new(
      self.
	gsub(/([a-z])([A-Z])/) { $1+' '+$2 }.	  # Break into words on change to capitals
	scan(/[[:alnum:]]*/).reject{|s| s == '' }	  # Break into distinct words on non-alnum
    )
  end
end

module ActiveFacts
  module Generate
    # Generate Scala module containing classes for an ActiveFacts vocabulary.
    # Invoke as
    #   afgen --ruby[=options] <file>.cql
    # Options are comma or space separated:
    # * help list available options

    class Scala < Helpers::OO

    private
      DataTypeMap = {
	"Signed Integer" => "Int",
	"Unsigned Integer" => "Int",
	"Real" => "Double",
	"Char" => "String",
	# REVISIT: More will be needed here.
      }
      LengthTypes = [ "String", "Decimal" ]
      ScaleTypes = [ "Decimal" ]

      def set_option(option)
        @mapping = false
        case option
        when 'help', '?'
          $stderr.puts "Usage:\t\tafgen --ruby[=option,option] input_file.cql\n"+
              "\t\tmeta\t\tModify the mapping to suit a metamodel"
#              "\t\tmapping=rails\tEmit data to enable mappings to Rails"
          exit 0
	when /^meta/
	  @is_metamodel = true
#        when /^mapping=(.*)/
#          @mapping = $1
#          @vocabulary.tables
        else super
        end
      end

      def fact_type_name(fact_type)
	fact_type.default_reading.words
      end

      def vocabulary_start(vocabulary)
	title_name = vocabulary.name.words.titlecase
        puts "package model\n"
	puts "\n"
        puts "import scala.language.implicitConversions\n"
	puts "\n"
        puts "object #{title_name} extends LocalStorageConstellation with #{title_name}\n"
	puts "\n"
        puts "trait #{title_name} extends Model {\n"
	# REVISIT: I think this next line should be model, not metaModel
	puts "  val metaModel = new #{title_name}Model()"
	puts

	@metamodel =
	  "class #{title_name}Model extends FBMModel with LocalStorageConstellation {\n" +
	  "  implicit val constellation: Constellation = this\n"
      end

      def vocabulary_end
        puts "}\n"
        puts "\n"
	@metamodel << "}"
        puts "#{@metamodel}\n"
      end

      def data_type_dump(o)
      end

      def value_type_dump(o, super_type_name, facets)
        name = o.name.words.titlecase
	if d = DataTypeMap[super_type_name]
	  super_type_name = d
	end
        super_type_title = super_type_name.words.titlecase
        super_type_camel = super_type_name.words.camelcase
	# REVISIT: Remove facets that do not apply to the Scala data types
        params = [
	  LengthTypes.include?(super_type_name) ? facets[:length] : nil,
	  ScaleTypes.include?(super_type_name) ? facets[:scale] : nil
	].compact * ", "

	sometimes_optional =  o.all_role.detect { |r| r.fact_type.all_role.size == 2 && c = (r.fact_type.all_role.to_a-[r])[0] and !c.is_mandatory}

        puts "  case class #{name}(value: #{super_type_title})(implicit val constellation: Constellation) extends FBMModel.ValueTypeValue[#{super_type_title}] {\n" +
             "    val objectType = metaModel.#{o.name.words.camelcase}\n"
#	REVISIT: Use the type params, if defined
#       REVISIT: Use the value restriction: puts "    restrict #{o.value_constraint.all_allowed_range_sorted.map{|ar| ar.to_s}*", "}\n" if o.value_constraint
#       REVISIT: Use the units: puts "    \# REVISIT: #{o.name} is in units of #{o.unit.name}\n" if o.unit
        roles_dump(o)
        puts "  }\n"

	# Add implicit casts for the underlying data type:
        puts "  implicit def #{super_type_camel}2#{name}(value: #{super_type_title})(implicit constellation: Constellation): #{name} = #{name}(value)\n"
	if sometimes_optional
	  puts "  implicit def #{super_type_camel}2#{name}Option(value: #{super_type_title})(implicit constellation: Constellation): Option[#{name}] = Some(#{name}(value))\n"
	end
        puts "\n"

	@metamodel <<
	  "  val #{o.name.words.camelcase} = assertEntity(FBMModel.ValueType(FBMModel.DomainObjectTypeName(\"#{name}\"), FBMModel.#{super_type_title}Type(#{params}), Nil))\n"
      end

      def id_role_names o, id_roles
	id_roles.map do |role|
	  # Ignore identification through a supertype
	  next if role.fact_type.kind_of?(ActiveFacts::Metamodel::TypeInheritance)
	  preferred_role_name(role, o).words.camelcase
	end.compact
      end

      def id_role_types id_roles
	id_roles.map do |role|
	  next if role.fact_type.kind_of?(ActiveFacts::Metamodel::TypeInheritance)
	  if !role.fact_type.entity_type && role.fact_type.all_role.size == 1
	    "Boolean"
	  else
	    role.object_type.name.words.titlecase
	  end
	end.compact
      end

      def subtype_dump(o, supertypes, pi = nil)
	entity_type_shared(o, supertypes, pi)
      end

      def non_subtype_dump(o, pi)
	subtype_dump(o, nil, pi)
      end

      def all_identifying_roles(o)
	pis = []
	# This places the subtype identifying roles before the supertype's. Reverse the list to change this.
	id_roles = []
	o.supertypes_transitive.each do |supertype|
	  pi = supertype.preferred_identifier
	  next if pis.include?(pi)   # Seen this identifier already?
	  pis << pi
          identifying_role_refs = pi.role_sequence.all_role_ref_in_order
	  identifying_role_refs.each do |id_role_ref|
	    # Have we seen this role in another identifier?
	    next if id_roles.detect{|idr| idr == id_role_ref.role }
	    id_roles << id_role_ref.role
	  end
	end
	[id_roles, pis]
      end

      def entity_object(title_name, id_names, id_types)
	puts "  object #{title_name} {"
	puts "    def apply(" +
	  (id_names.zip(id_types).map do |(name, type_name)|
	    "#{name}: #{type_name}"
	  end * ', '
	  ) +
	")(implicit constellation: Constellation) = {\n"

	# Define the constant storage for the identifying role values:
	id_names.each do |name|
	  puts "      val _#{name} = #{name}"
	end
	puts "      val _constellation = constellation"

	puts "      assertEntity(new #{title_name} {"
	  id_names.each do |name|
	    puts "        val #{name} = _#{name}"
	  end
	puts "        val constellation = _constellation"
	puts "      })\n"	# Ends new block and assertEntity
	puts "    }\n"		# Ends apply()
	puts "  }\n"		# Ends object{}
	puts "\n"
      end

      def entity_trait(o, title_name, primary_supertype, pis)
	puts "  trait #{title_name} extends #{primary_supertype ? primary_supertype.name.words.titlecase : 'FBMModel.Entity'} {"
	s = 'override ' unless o.supertypes.empty?
	puts "    #{s}val objectType = metaModel.#{o.name.words.camelcase}"

        puts "  // REVISIT: Here, we should use fact_roles_dump(o.fact_type)\n\n" if o.fact_type
        roles_dump(o)

	puts "    #{s}val identifier: Seq[Seq[FBMModel.Identifier[_]]] = Seq(#{
	  pis.map do |pi|
	    'Seq(' +
	      pi.role_sequence.all_role_ref_in_order.map do |id_role_ref|
		id_role_ref.role.object_type.name.words.camelcase
	      end*', ' +
	    ')'
	  end*', '
	})\n"
	puts "  }\n"		# Ends trait{}
	puts "\n"
      end

      def entity_model(o, title_name)
	pi = o.preferred_identifier
	# The following finds the closest non-inheritance identifier
	#while pi.role_sequence.all_role_ref.size == 1 and
	#    (role = pi.role_sequence.all_role_ref.single.role).fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance)
	#  pi = role.fact_type.supertype_role.object_type.preferred_identifier
	#end
	identifying_parameters =
	  pi.role_sequence.all_role_ref_in_order.map{|rr| rr.role.object_type.name.words.camelcase }*', '
	supertypes_list =
	  if o.supertypes.empty?
	    'Nil'
	  else
	    "List(#{o.supertypes.map{|s| s.name.words.camelcase}*', '})"
	  end
	@metamodel <<
	  "  val #{o.name.words.camelcase} = assertEntity(FBMModel.EntityType(FBMModel.DomainObjectTypeName(\"#{title_name}\"), #{supertypes_list}, Seq(#{identifying_parameters})))\n"
      end

      def entity_type_shared(o, supertypes, pi = nil)
	if supertypes
	  primary_supertype = o && (o.identifying_supertype || o.supertypes[0])
	end
	title_name = o.name.words.titlecase

	id_roles, pis = *all_identifying_roles(o)
	id_names = id_role_names(o, id_roles)
	id_types = id_role_types(id_roles)
	identification = pi ? identified_by(o, pi) : nil

	# REVISIT: We don't want an object for abstract classes,
	# i.e. where subtypes have a disjoint mandatory constraint
	entity_object(title_name, id_names, id_types)

	entity_trait(o, title_name, primary_supertype, pis)

	entity_model(o, title_name)

        @constraints_used[pi] = true if pi
      end

      def identified_by_roles_and_facts(entity_type, identifying_role_refs, identifying_facts)
        identifying_role_refs.map do |role_ref|
            [ preferred_role_name(role_ref.role, entity_type),
              entity_type.name.words.titlecase
            ]
          end
      end

      def skip_fact_type(f)
	f.is_a?(ActiveFacts::Metamodel::TypeInheritance)
      end

      # Dump one fact type.
      def fact_type_dump(fact_type, name)
        @fact_types_dumped[fact_type] = true
        if fact_type.entity_type
	  objectified_fact_type_dump(fact_type.entity_type)
	  return
	end

	# Dump a non-objectified fact type
	name_words = fact_type_name(fact_type)
	role_names = fact_type.preferred_reading.role_sequence.all_role_ref_in_order.map do |rr|
	    preferred_role_name(rr.role).words.camelcase
	  end
	role_types = fact_type.preferred_reading.role_sequence.all_role_ref_in_order.map do |rr|
	    rr.role.object_type.name.words.camelcase
	  end

	puts "  case class #{name_words.titlecase}(#{role_names.zip(role_types).map{|n, t| n+': '+t}*', '})(implicit val constellation: Constellation) extends FBMModel.BinaryFact {\n"
	puts "    def factType = metaModel.#{name_words.camelcase}\n"
	puts "    def rolePlayers = (#{role_names*', '})\n"
	puts "  }\n\n"

	@metamodel <<
	  "  val #{name_words.camelcase} = assertEntity(FBMModel.BinaryFactType(FBMModel.FactTypeName(\"#{name_words.titlecase}\"), (#{role_names*', '})))\n"
      end

      def objectified_fact_type_dump o
	# REVISIT: This disregards any supertypes and their identifiers
#       primary_supertype = o && (o.identifying_supertype || o.supertypes[0])
#       secondary_supertypes = o.supertypes-[primary_supertype]

        pi = o.preferred_identifier
	id_roles = []
	identifying_role_refs = pi.role_sequence.all_role_ref_in_order
	identifying_role_refs.each do |id_role_ref|
	  id_roles << id_role_ref.role
	end
	id_names = id_role_names o, id_roles
	id_types = id_role_types id_roles

	puts "  case class #{o.name.words.titlecase}(#{
	    id_names.zip(id_types).map {|(n, t)|
	      "#{n}: #{t}"
	    }*', '
	  }) extends FBMModel.ObjectifiedFact {"
        puts "    // REVISIT: Here, we should use fact_roles_dump(o.fact_type)"
        roles_dump(o)
	puts "  }"

	identifying_parameters =
	  pi.role_sequence.all_role_ref_in_order.map{|rr| rr.role.object_type.name.words.camelcase }*', '
	@metamodel <<
	  "  val #{o.name.words.camelcase} = assertEntity(FBMModel.ObjectifiedType(FBMModel.DomainObjectTypeName(\"#{o.name.words.titlecase}\"), Nil, Seq(#{identifying_parameters})))\n"

      end

      def unary_dump(role, role_name)
	scala_role_name = role_name.words.camelcase
	puts "    val #{scala_role_name}: Boolean"
      end

      def role_dump(role)
	return if role.fact_type.entity_type

	fact_type = role.fact_type
	if fact_type.all_role.size == 1
	  unary_dump(role, preferred_role_name(role))
	  return
	elsif fact_type.all_role.size != 2
	  # Shouldn't come here, except perhaps for an invalid model
	  return  # ternaries and higher are always objectified
	end

	return if fact_type.is_a?(ActiveFacts::Metamodel::TypeInheritance)

	other_role = fact_type.all_role.select{|r| r != role}[0]
	other_role_name = preferred_role_name(other_role)
	scala_role_name = other_role_name.words.camelcase
	other_type_name = other_role.object_type.name.words.titlecase

	if role.is_functional
	  if role.is_mandatory
	    # Define a getter for a mandatory value:
	    puts "    val #{scala_role_name}: #{other_type_name}"
	    if !role.fact_type.is_existential
	      puts "    def #{scala_role_name}_=(_value: #{other_type_name}) = { #{scala_role_name} = _value }"
	    end
	  else
	    # Define a getter for an optional value:
	    # REVISIT: The role number here depends on the metamodel ordering of the fact type roles.
	    # This likely should follow the role order of the preferred reading, from which the fact name is derived.
	    # The code here collows the order of definition of the roles in the fact type,
	    # which might not be the same as the order of the preferred reading:
	    fact_name = fact_type_name(role.fact_type).titlecase
	    role_number = role.fact_type.all_role_in_order.index(other_role)+1
	    puts "    def #{scala_role_name}: Option[#{other_type_name}] = {"
	    puts "      constellation.getBinaryFact(metaModel.#{fact_name.words.camelcase}, this).map(x => {"
	    puts "        x.head.asInstanceOf[FBMModel.BinaryFact].rolePlayers._#{role_number}.asInstanceOf[#{other_type_name}]"
	    puts "      })"
	    puts "    }"

	    if !role.fact_type.is_existential
	      # Define a setter for an optional value:
	      puts "    def #{scala_role_name}_=(value: Option[#{other_type_name}]) = {"
	      puts "      value match {"
	      puts "        case None =>"
	      puts "        case Some(m) => constellation.assertBinaryFact(#{fact_name.words.titlecase}(this, m))"
	      puts "      }"
	      puts "    }"
	    end
	  end
	elsif other_role.object_type.fact_type
	  # An objectified fact type
	  puts <<"END"
    def all#{scala_role_name.words.titlecase}(implicit constellation: Constellation): Seq[#{other_type_name}] = {
      constellation.getObjectifiedFact(metaModel.#{scala_role_name.words.camelcase}, this).getOrElse(Nil).flatMap(x => x match {
	case o: #{other_type_name} => Some(o)
	case _ => None
      })
    }
END
	else
	  puts <<"END"
    /*
    def all#{scala_role_name.words.titlecase}(implicit constellation: Constellation): Seq[#{other_type_name}] = {
      constellation.getFact(metaModel.#{scala_role_name.words.camelcase}, this).getOrElse(Nil).flatMap(x => x match {
	# REVISIT: This is incorrect; we want to return the other role player in the fact
	case o: #{other_type_name} => Some(o)
	case _ => None
      })
    }
    */
END
	end
      end

    end
  end
end

ActiveFacts::Registry.generator('scala', ActiveFacts::Generate::Scala)

