#
# ActiveFacts CQL parser and loader.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
require 'rubygems'
require 'treetop'

# These are Treetop files, which it will compile on the fly if precompiled ones aren't found:
require 'activefacts/cql/LexicalRules'
require 'activefacts/cql/Language/English'
require 'activefacts/cql/Expressions'
require 'activefacts/cql/Concepts'
require 'activefacts/cql/DataTypes'
require 'activefacts/cql/FactTypes'
require 'activefacts/cql/CQLParser'

module ActiveFacts
  # Extend the generated parser:
  class CQLParser
    include ActiveFacts

    def initialize
      @types = {}
      @role_names = {}    # Indexed by role name and/or adjectival form
      @fact_types_by_sorted_players = Hash.new {|h, k| h[k] = []}
      @linking_words = {}         # For checking forward-references
    end

    # Repeatedly parse rule_name until all input is consumed,
    # returning an array of syntax trees for each definition.
    def parse_all(input, rule_name = nil, &block)
      self.root = rule_name if rule_name

      @index = 0  # Byte offset to start next parse
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

    # REVISIT: These can't be used until we've done fact type lookup to detect unmarked adjectives.
    def linking_word(name)
      @linking_words[name] = true
    end

    def linking_word?(name)
      @linking_words[name]
    end

    def type_by_name(name)
      @types[name] # REVISIT: Do we need this: || @role_names[w]
    end

    # REVISIT: Need to handle standard types better here:
    def standard_type(name)
      %w{Date DateAndTime}.include?(name)
    end

    def define_fact_type(name, defined_readings, clauses)
      # REVISIT: Create a name from the whole reading if necessary.
      fact_type = [:fact_type, name, defined_readings, clauses]

      @types[name] = fact_type if name

      # Index the new fact type by its sorted players list
      players = defined_readings[0][2].map{|w|
          Hash === w ? w[:player] : nil
        }.compact
      sorted_players = players.sort

      @fact_types_by_sorted_players[sorted_players] << fact_type
      fact_type
    end

    def fact_types_by_players(players)
      debug "Sorted list of fact type players: " + players.sort.inspect
      @fact_types_by_sorted_players[players.sort]
    end

    def definition(node)
      name, definition = *node.value
      kind, *value = *definition

      if name && linking_word?(name)
        debug "Can't define #{kind} #{name} after it's already been used as a linking word"
        return
      end

      begin
        debug "Processing #{[kind, name].compact*" "}" do
          reset_defined_roles
          case kind
          when :vocabulary
            [kind, name]
          when :data_type
            data_type(name, value)
          when :entity_type
            supertypes = value.shift
            entity_type(name, supertypes, value)
          when :fact_type
            f = fact_type(name, value)
          end
        end
      end
    rescue => e
      raise "in #{kind.to_s.camelcase(true)} definition, #{e.message}:\n\t#{node.text_value}"
    end

    def data_type(name, value)
      debug value.inspect do
        # REVISIT: Massage/check data type here?
        @types[name] = [:data_type, name, *value]
      end
    end

    def entity_type(name, supertypes, value)
      #print "entity_type parameters for #{name}: "; p value
      identification, clauses = *value
      clauses ||= []

      # The entity is treated as a local role:
      @local_roles[name] = true

      raise "Entity type clauses must all be fact types" if clauses.detect{|c| c[0] != :fact_clause }
      find_all_defined_roles(clauses)

      if identification and id_roles = identification[:roles]
        debug "Checking for forward-referenced identifying roles" do
          id_roles.each do |id_role|
            debug id_role.inspect

            # REVISIT: Separate the role player from the adjectives in the id_role
            # @local_roles, @local_forms

            if id_role.size == 1
              w = id_role[0]
              unless (@local_roles[w] or type_by_name(w))
                debug "Forward referenced Entity Type #{w}"
                # Treat it like a local role
                @local_roles[w] = true
              end
            end
          end
        end
      end

      debug "Entity known by #{identification.inspect}" do
        clauses.each{|c| clause(c) }
      end

      @types[name] = [:entity_type, name, supertypes, identification, clauses]
    end

    def fact_type(name, value)
      defined_readings, *clauses = value

      # We have to handle all fact clauses one way, conditions another:
      fact_clauses = defined_readings +
        clauses.select{|c| c[0] == :fact_clause }

      find_all_defined_roles(fact_clauses)

      # Process all fact invocations in both the defined_readings and the clauses:
      fact_clauses.each{|r| clause(r) }

      #debug "Defined readings: "+defined_readings.inspect
      debug "Fact derivation clauses: "+clauses.inspect if clauses.size > 0

      define_fact_type(name, defined_readings, clauses)
    end

    def reset_defined_roles
      @local_roles = {}
      @local_forms = {}
      @local_forms_by_word = {}
    end

    # Extract any role names into @local_roles and
    # any defined adjectival forms into @local_forms
    # (also indexed by word as @local_forms)
    def find_all_defined_roles(fact_clauses)
      debug "Search fact readings for role names:" do
        fact_clauses.each do |r|
          reading = r[2]
          reading.each do |role|
            # Index the role_name if any:
            role_name = role[:role_name]
            @local_roles[role_name] = role if role_name

            # Index the adjectival form, if any marked adjectives:
            leading_adjective = role[:leading_adjective]
            trailing_adjective = role[:trailing_adjective]
            next unless leading_adjective || trailing_adjective

            form = [leading_adjective, role[:words], trailing_adjective].flatten.compact
            debug "Adjectival form: "+ form.inspect
            @local_forms[form] = true
            form.each{|w| (@local_forms_by_word[w] ||= []) << form }
          end
        end
        debug "Role names: "+ @local_roles.inspect if @local_roles.size > 0
      end
    end

    def clause(c)
      case c[0]
      when :fact_clause
        qualifiers = c[1]
        roles = c[2]
        canonicalise_reading(qualifiers, roles)
        debug "Adjusted Roles: "+roles.inspect
      else
        debug "clause #{c.inspect} not handled yet"
      end
    end

    # A reading consists of an array of roles, of which each is a hash which
    # may have the following keys:
    #   :quantifier (an array of two elements, each either a number of nil)
    #   :leading_adjective (a word that we know to be the first adjective)
    #   :words (words including the role player and possibly some adjectives)
    #   :trailing_adjective (a word that we know to be a trailing adjective)
    #   :function
    #   :role_name (from "(as xyz)")
    #   :restriction (from "restricted to {a-b,c}..."
    #   :literal (the lexical representation of a value)
    #
    # The interesting one here is :words, which might contain:
    # - linking words (e.g. "has", "is" "of"),
    # - adjectives
    # - role players (either type names, or role names from "(as role_name)").
    #
    # We must sift these three classes of words. Adjectives and role names might
    # be defined either in this query or in the fact types that are being invoked.
    # If it's in this query, it might be this clause (reading) or another one.
    # 
    # Role names must not conflict with role players in the name space of this
    # declaration. We must first have enumerated any locally-defined role names.
    # While doing that, we enumerated any adjectival forms defined in this
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
    def canonicalise_reading(qualifiers, roles)
      # Identify all role players and expand the adjectives and linking words:
      replacement_roles =
        roles.inject([]){|new_roles, role|
          debug "Processing role #{role.inspect}"

          words = role[:words]
          role.delete(:words)

          # A quantifier or a leading adjective comes before the :words,
          # so leading words before the role player must also be leading
          # adjectives. The existence of role[:leading_adjective] indicates
          # that this should happen.
          la = role[:leading_adjective]
          role[:leading_adjective] = Array(la) if (la)   # Make it an array
          quant = role[:quantifier]
          role[:leading_adjective] ||= [] if quant  # Start an empty array
          la = role[:leading_adjective]
          ta = role[:trailing_adjective]
          role[:trailing_adjective] = Array(ta) if ta

          new_role = nil
          possible_extra_trailing_adjectives = []
          words.each{|w|
              local_role = @local_roles[w]
              # REVISIT: Case in point: In the clauses of an entity definition, the entity name is a local role
              if (local_role || type_by_name(w) || standard_type(w))
                # We've found a role player. The quantifier & leading adjectives
                # go with the first player found, the trailing adjectives, function,
                # role name, restriction and literal with the last one... sigh.

                # Any possible extra trailing adjectives on the previous role
                # turned out to actually be just linking words, so emit them:
                new_roles.concat possible_extra_trailing_adjectives
                possible_extra_trailing_adjectives = []

                # REVISIT: Deal with the following:
                #   :function
                #   :role_name (from "(as xyz)")
                #   :restriction (from "restricted to {a-b,c}..."
                #   :literal (the lexical representation of a value)

                new_role = {:player => w}
                new_role[:quantifier] = quant if quant
                new_role[:leading_adjective] = la if la
                quant = la = nil
                new_roles << new_role
                role.delete(:quantifier)
                role.delete(:leading_adjective)
              else        # Not a role player
                if la
                  la << w               # Extra leading adjective
                elsif (ta = role[:trailing_adjective]) # Extra trailing adjective
                  possible_extra_trailing_adjectives << w
                else
                  new_roles << w        # Adjective or linking word
                end
              end
            }
          # Merge remaining parameters into the last role created, if any
          if (ta = role[:trailing_adjective]) # Extra trailing adjectives
            possible_extra_trailing_adjectives.each{|w|
                role[:trailing_adjective] = ta.unshift(w)
              }
          else  # Just linking words
            possible_extra_trailing_adjectives.each{|w| new_roles << w }
          end
          new_role.merge!(role) if new_role

          if (la)
            raise "Role player #{la[-1]} for '#{la*" "}' not found" + " in #{role.inspect}"
          end

          new_roles
        }
      roles.replace(replacement_roles)
    end

    #
    # Then we do the adjective matching. Since we know all the existing fact
    # types for the current list of players, we can match the adjectives
    # against the candidate fact types (including worrying about adjectival
    # forms introduced elsewhere in this query).
    #
    def bind_fact_invocation(qualifiers, roles)
      debug "roles: " + roles.inspect

      # REVISIT: We might have role names as players. A role name from the
      # current query must be substituted for the player - but not one that
      # is defined in an invoked fact type.

      # Find all possible existing fact types that might contain these players.
      # REVISIT: Replace local_roles with the type they stand for:
      players = roles.inject([]) {|a, r| p = r[:player]; a << p if p; a }

      candidates = fact_types_by_players(players)
      # REVISIT: What about the fact type we're defining; can that be invoked?

      debug "candidate fact types: " + candidates.inspect
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
