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

module ActiveFacts
  module Metamodel

    class ObjectType
      def camelName
	name.gsub(/ /,'').sub(/^[A-Z]/) {|i| i.downcase}
      end

      def title_name
	name.gsub(/ /,'').sub(/^[a-z]/) {|i| i.upcase}
      end
    end

    class Vocabulary
      def camelName
	name.gsub(/ /,'').sub(/^[A-Z]/) {|i| i.downcase}
      end

      def title_name
	name.gsub(/ /,'').sub(/^[a-z]/) {|i| i.upcase}
      end
    end
  end

  module Generate
    # Generate Ruby module containing classes for an ActiveFacts vocabulary.
    # Invoke as
    #   afgen --ruby[=options] <file>.cql
    # Options are comma or space separated:
    # * help list available options
    class Scala < Helpers::OO
    private

      def set_option(option)
        @mapping = false
        case option
        when 'help', '?'
          $stderr.puts "Usage:\t\tafgen --ruby[=option,option] input_file.cql\n"+
              "\t\tmeta\t\tModify the mapping to suit a metamodel"
#              "\t\tmapping=rails\tEmit data to enable mappings to Rails"
          exit 0
	when /^meta/
	  @metamodel = true
#        when /^mapping=(.*)/
#          @mapping = $1
#          @vocabulary.tables
        else super
        end
      end

      def vocabulary_start(vocabulary)
        puts "package model\n"
	puts "\n"
        puts "object #{vocabulary.title_name} extends LocalStorageConstellation with #{vocabulary.title_name}\n"
	puts "\n"
        puts "trait #{vocabulary.title_name} extends Model {\n"
	# REVISIT: I think this next line should be model, not metaModel
	puts "  val metaModel = new #{vocabulary.title_name}Model()"
	puts

	@metamodel =
	  "class #{vocabulary.title_name}Model extends FBMModel with LocalStorageConstellation {\n"
      end

      def vocabulary_end
        puts "}\n"
        puts "\n"
	@metamodel << "}"
        puts "#{@metamodel}\n"
      end

      def value_type_dump(o)
        length = (l = o.length) && l > 0 ? "#{l}" : nil
        scale = (s = o.scale) && s > 0 ? "#{s}" : nil
        params = [length,scale].compact * ", "

        return if
          !o.supertype &&                   # No supertype, i.e. a base type
          o.all_role.size == 0 &&           # No roles
          !o.is_independent &&              # not independent
          o.all_instance.size == 0          # No instances

        name = o.title_name
        super_type_name = o.supertype ? o.supertype.title_name : name

        puts "  case class #{name}(value: #{super_type_name}) extends FBMModel.ValueTypeValue[#{super_type_name}] {\n" +
             "    val objectType = metaModel.#{o.camelName}\n"
#	REVISIT: Use the type params, if defined
#       REVISIT: Use the value restriction: puts "    restrict #{o.value_constraint.all_allowed_range_sorted.map{|ar| ar.to_s}*", "}\n" if o.value_constraint
#       REVISIT: Use the units: puts "    \# REVISIT: #{o.name} is in units of #{o.unit.name}\n" if o.unit
        puts "  }\n"
        puts "\n"

	@metamodel <<
	  "  val #{o.camelName} = assertEntity(FBMModel.ValueType(FBMModel.DomainObjectTypeName(\"#{o.title_name}\"), FBMModel.#{super_type_name}Type(#{[length, scale].compact*', '}), Nil))\n"
      end

      def id_role_names o, id_roles
	id_roles.map do |role|
	  next if role.fact_type.kind_of?(ActiveFacts::Metamodel::TypeInheritance)
	  # This block converts the array of names into camelCase instead of the default snakecase:
	  preferred_role_name(role, o) { |names|
	    (names[0]||'').downcase +
	    Array(names[1..-1]).map{|n| n.downcase.sub(/^[a-z]/){|f| f.upcase}}*''
	  }
	end.compact
      end

      def id_role_types id_roles
	id_roles.map do |role|
	  next if role.fact_type.kind_of?(ActiveFacts::Metamodel::TypeInheritance)
	  !role.fact_type.entity_type && role.fact_type.all_role.size == 1 ? "Boolean" : role.object_type.title_name
	end.compact
      end

      def subtype_dump(o, supertypes, pi = nil)
	if supertypes
	  primary_supertype = o && (o.identifying_supertype || o.supertypes[0])
	end

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

	id_names = id_role_names o, id_roles
	id_types = id_role_types id_roles

	identification = pi ? identified_by(o, pi) : nil

	# REVISIT: We don't want an object for abstract classes,
	# i.e. where subtypes have a disjoint mandatory constraint

        puts "  object #{o.title_name} {"
	puts "    def apply(" +
	  (id_names.zip(id_types).map do |(name, type_name)|
	    "#{name}: #{type_name}"
	  end * ', '
	  ) +
	") = {\n"

	# Define the constant storage for the identifying role values:
	id_names.each do |name|
	  puts "      val _#{name} = #{name}"
	end

	puts "      new #{o.title_name} {"
	  id_names.each do |name|
	    puts "        val #{name} = _#{name}"
	  end
	puts "      }\n"	# Ends new block
	puts "    }\n"		# Ends apply()
	puts "  }\n"		# Ends object{}
	puts "\n"

        puts "  trait #{o.title_name} extends #{primary_supertype ? primary_supertype.title_name : 'FBMModel.Entity'} {"
	s = 'override ' unless o.supertypes.empty?
	puts "    #{s}val objectType = metaModel.#{o.camelName}"

        puts "  // REVISIT: Here, we should use fact_roles_dump(o.fact_type)\n\n" if o.fact_type
        roles_dump(o)

	puts "    #{s}val identifier: Seq[Seq[FBMModel.Identifier[_]]] = Seq(#{
	  pis.map do |pi|
	    'Seq(' +
	      pi.role_sequence.all_role_ref_in_order.map do |id_role_ref|
		id_role_ref.role.object_type.title_name
	      end*', ' +
	    ')'
	  end*', '
	})\n"
	puts "  }\n"		# Ends trait{}
	puts "\n"

	identifying_parameters =
	  o.preferred_identifier.role_sequence.all_role_ref_in_order.map{|rr| rr.role.object_type.camelName }*', '
	supertypes_list =
	  if o.supertypes.empty?
	    'Nil'
	  else
	    "List(#{supertypes.map{|s| s.camelName}*', '})"
	  end
	@metamodel <<
	  "  val #{o.camelName} = assertEntity(FBMModel.EntityType(FBMModel.DomainObjectTypeName(\"#{o.title_name}\"), #{supertypes_list}, Seq(#{identifying_parameters})))\n"

        @constraints_used[pi] = true if pi
      end

      def non_subtype_dump(o, pi)
	subtype_dump(o, nil, pi)
      end

      def identified_by_roles_and_facts(entity_type, identifying_role_refs, identifying_facts)
        identifying_role_refs.map do |role_ref|
            [ preferred_role_name(role_ref.role, entity_type),
              entity_type.title_name
            ]
          end
      end

      # Dump one fact type.
      def fact_type_dump(fact_type, name)
        return if skip_fact_type(fact_type)
        o = fact_type.entity_type

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

	puts "  case class #{o.title_name}(#{
	    id_names.zip(id_types).map {|(n, t)|
	      "#{n}: #{t}"
	    }*', '
	  }) extends FBMModel.ObjectifiedFact {"
        puts "    // REVISIT: Here, we should use fact_roles_dump(fact_type)"
        roles_dump(o)
	puts "  }"

	identifying_parameters =
	  pi.role_sequence.all_role_ref_in_order.map{|rr| rr.role.object_type.camelName }*', '
	@metamodel <<
	  "  val #{o.camelName} = assertEntity(FBMModel.ObjectifiedType(FBMModel.DomainObjectTypeName(\"#{o.title_name}\"), Nil, Seq(#{identifying_parameters})))\n"

        @fact_types_dumped[fact_type] = true
      end

      def unary_dump(role, role_name)
	scala_role_name = role_name.gsub(/ /,'_').camelcase(:lower)
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
	scala_role_name = other_role_name.gsub(/ /,'_').camelcase(:lower)
	other_type_name = other_role.object_type.name.gsub(/ /,'').camelcase

	if role.is_functional
	  puts "    val #{scala_role_name}: #{other_type_name}"
	elsif other_role.object_type.fact_type
	  # An objectified fact type
	  puts <<"END"
    def all#{scala_role_name.camelcase}(implicit constellation: Constellation): Seq[#{other_type_name}] = {
      constellation.getObjectifiedFact(metaModel.#{scala_role_name.camelcase(:lower)}, this).getOrElse(Nil).flatMap(x => x match {
	case o: #{other_type_name} => Some(o)
	case _ => None
      })
    }
END
	else
	  puts <<"END"
    def all#{scala_role_name.camelcase}(implicit constellation: Constellation): Seq[#{other_type_name}] = {
      constellation.getFact(metaModel.#{scala_role_name.camelcase(:lower)}, this).getOrElse(Nil).flatMap(x => x match {
	# REVISIT: This is incorrect; we want to return the other role player in the fact
	case o: #{other_type_name} => Some(o)
	case _ => None
      })
    }
END
	end
      end

    end
  end
end

ActiveFacts::Registry.generator('scala', ActiveFacts::Generate::Scala)

