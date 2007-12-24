require 'rubygems'
require 'polyglot'
require 'treetop'

module ActiveFacts

  class CQLParser < Treetop::Runtime::CompiledParser
    def self.load(file)
      puts "Loading #{file}"
      parser = ActiveFacts::CQLParser.new

      File.open(file) do |f|
	result = parser.parse_all(input = f.read, :definition) { |node|
	    parser.definition(node)
	    nil
	  }
	raise parser.failure_reason unless result
      end
    end

    def initialize
      @types = {}
      @roles = {}	  # Indexed by role name and/or adjectival form
      @fact_types_by_sorted_players = Hash.new {|h, k| h[k] = []}
      @other_words = {}	  # For checking forward-references
    end

    # Repeatedly parse rule_nae until all input is consumed:
    def parse_all(input, rule_name = nil, &block)
      self.root = rule_name if rule_name

      @index = 0
      self.consume_all_input = false
      results = []
      begin
	node = parse(input, :index => @index)
	return nil unless node
	node = block.call(node) if block
	results << node if node
      end until self.index == @input_length
      results
    end

    def definition(node)
      name, definition = *node.value
      kind, *value = *definition

      if name && @other_words[name]
	puts "Can't define #{kind} #{name} after it's already been used as a linking word"
	return
      end

      puts "Processing #{[kind, name].compact*" "}"

      case kind
      when :data_type
	  data_type(name, value)
      when :entity_type
	  entity_type(name, value)
      when :fact_type
	  fact_type(name, value)
      end
    end

    def data_type(name, value)
      #p value
      @types[name] = [:data_type, value]
    end

    def entity_type(name, value)
      @types[name] = [:entity_type, value]
      identification, clauses = *value
      puts "Entity known by #{identification.inspect}" \
#	+ clauses.map{|c| "\n\t"+c.inspect }*""
#      clauses.each{|c| clause(c) }
    end

    def fact_type(name, value)
      defined_readings, *clauses = value
      #p defined_readings
      #p clauses

      # We have to handle all fact clauses one way, conditions another:
      fact_clauses = defined_readings +
	clauses.select{|c| c[0] == :fact_clause }

      # Extract any role names into @local_roles and
      # any defined adjectival forms into @local_forms
      @local_roles = {}
      @local_forms = {}
      @local_forms_by_word = {}
      fact_clauses.each{|r| find_defined_roles(r[2]) }
      print "Role names: "; p @local_roles

      # Process all fact invocations in both the defined_readings and the clauses:
      fact_clauses.each{|r| clause(r) }

      # REVISIT: Check that all defined readings have the same set of players

      # Index the new fact type by its sorted players list
      players = defined_readings[0][2].map{|w|
	  Hash === w ? w[:player] : nil
	}.compact
      sorted_players = players.sort

      fact_type = [:fact_type, value]
      @fact_types_by_sorted_players[sorted_players] = fact_type

      # REVISIT: Create a name from the whole reading if necessary.

      @types[name] = fact_type if name
    end

    def find_defined_roles(reading)
      # print "Search reading for roles names: "; p reading
      reading.each { |role|
	  role_name = role[:role_name]
	  @local_roles[role_name] = role if role_name
	  leading_adjective = role[:leading_adjective]
	  trailing_adjective = role[:trailing_adjective]
	  next unless leading_adjective || trailing_adjective
	  form = [leading_adjective, role[:words], trailing_adjective].flatten.compact
	  print "Adjectival form: "; p form
	  @local_forms[form] = true
	  form.each{|w| (@local_forms_by_word[w] ||= []) << form }
	}
    end

    def clause(c)
      case c[0]
      when :fact_clause
	reading(c[1], c[2])
      else
	puts "clause #{c.inspect} not handled yet"
      end
    end

    # A reading consists of an array of roles, of which each is a hash which
    # may have the following keys:
    #   :quantifier
    #   :leading_adjective
    #   :words
    #   :trailing_adjective
    #   :function
    #   :role_name
    #   :restriction
    #   :literal
    #
    # The interesting one is :words, which might contain:
    # - linking words (e.g. "has", "is" "of"),
    # - adjectives
    # - role players (either type names, or role names from "(as role_name)").
    # We must sift these three classes of words. In the case of both adjectives
    # and role names, these might be defined in this query or in the fact types
    # that are being invoked.
    # 
    # Role names cannot conflict with type names in the current name space.
    # We must first enumerate any locally-defined role names in this query.
    # While doing that, we enumerate any adjectival forms defined in this
    # query as well. These have both happened before we come here. The results
    # are in @local_roles and @local_forms (indexed by @local_forms_by_word).
    #
    # So here, we first identify the role player in each role, using the role
    # names and the type names.
    #
    # Any words preceeding or following the role player are initially presumed
    # to be linking words (not adjectives) and get removed from this role and
    # moved to the role list either before or after, since they might bind to
    # the adjacent role.
    #
    # Then we do the adjective matching. Since we know all the existing fact
    # types for the current list of players, we can match the adjectives
    # against the candidate fact types (including worrying about adjectival
    # forms introduced elsewhere in this query).
    #
    def reading(qualifiers, roles)
      # Identify all role players and expand the adjectives and linking words:
      #puts "v"*60
      roles.replace(roles.inject([]){|new_roles, role|
	  #print ">"*10+" adding role: "; p role

	  words = role[:words]
	  role.delete(:words)

	  # If we have a quantifier or a leading adjective, we handle it differently.
	  # In this case the leading words up to the player get added to a leading
	  # adjectives array.
	  la = role[:leading_adjective]
	  role[:leading_adjective] = [la] if (la)   # Make it an array
	  quant = role[:quantifier]
	  role[:leading_adjective] ||= [] if quant	# Start an empty array
	  la = role[:leading_adjective]
	  ta = role[:trailing_adjective]
	  role[:trailing_adjective] = Array(ta) if ta

	  new_role = nil
	  possible_extra_trailing_adjectives = []
	  words.each{|w|
	      local_role = @local_roles && @local_roles[w]
	      if (local_role || @types[w]) # REVISIT: Do we need this? || @roles[w]
		# We've found a role player. The quantifier & leading adjectives
		# go with the first player found, the trailing adjectives, function,
		# role name, restriction and literal with the last one... sigh.

		# Ok, these weren't extra trailing adjectives after all
		possible_extra_trailing_adjectives.each{|l| new_roles << l }
		possible_extra_trailing_adjectives = []

		new_role = {:player => w}
		new_role[:quantifier] = quant if quant
		new_role[:leading_adjective] = la if la
		quant = la = nil
		new_roles << new_role
		role.delete(:quantifier)
		role.delete(:leading_adjective)
	      else
		if la
		  la << w		# Extra leading adjective
		elsif (ta = role[:trailing_adjective]) # Extra trailing adjective
		  possible_extra_trailing_adjectives << w
		else
		  new_roles << w	# Adjective or linking word
		end
	      end
	    }
	  # Merge remaining parameters into the last role created, if any
	  if (ta = role[:trailing_adjective]) # Extra trailing adjectives
	    possible_extra_trailing_adjectives.each{|w|
		role[:trailing_adjective] = ta.unshift(w)
	      }
	  else	# Just linking words
	    possible_extra_trailing_adjectives.each{|w| new_roles << w }
	  end
	  new_role.merge!(role) if new_role

	  new_roles
	}
      )
      print "Expanded roles: "; p roles

      # REVISIT: We might have role names as players. A role name from the
      # current query must be substituted for the player - but not one that
      # is defined in an invoked fact type.

      # Find all possible existing fact types that might contain these players.
      # REVISIT: Replace local_roles with the type they stand for:
      players = roles.inject([]) {|a, r| p = r[:player]; a << p if p; a }
      sorted_players = players.sort
      candidates = @fact_types_by_sorted_players[sorted_players]
      # REVISIT: What about the fact type we're defining; can that be invoked?

print "candidate fact types: "; p candidates
return

      # Now we absorb adjectives in where possible.
      # Basically we take each candidate fact type in turn, and for each player
      # in that fact type, check whether all the adjectives it requires are
      # present in this invocation, and the linking words match too.
      # REVISIT: Incomplete

    end
  end
  
  Polyglot.register('cql', CQLParser)
end

require 'activefacts/cql/CQLParser'
