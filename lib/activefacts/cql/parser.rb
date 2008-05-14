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

$debug_indent = 0
def debug(arg, &block)
  puts "  "*$debug_indent + arg
  $debug_indent += 1
  yield if block
  $debug_indent -= 1
end

module ActiveFacts
  # Extend the generated parser:
  class CQLParser

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

=begin
    def definition(node)
      name, definition = *node.value
      kind, *value = *definition

      if name && linking_word?(name)
        debug "Can't define #{kind} #{name} after it's already been used as a linking word"
        return
      end

      debug "Processing #{[kind, name].compact*" "}" do
        reset_defined_roles
        case kind
        when :data_type
          data_type(name, value)
        when :entity_type
            supertypes = value.shift
            entity_type(name, supertypes, value)
        when :fact_type
          fact_type(name, value)
        end
      end
    end

    def data_type(name, value)
      debug value.inspect do
        # REVISIT: Massage/check data type here?
        define_data_type(name, value)
      end
    end

    def entity_type(name, supertypes, value)
      #print "entity_type parameters for #{name}: "; p value
      identification, clauses = *value

      raise "Entity type clauses must all be fact types" if clauses.detect{|c| c[0] != :fact_clause }
      find_all_defined_roles(clauses)

      debug "Entity known by #{identification.inspect}" do
        clauses.each{|c| clause(c) }
      end

      define_entity_type(name, identification, clauses)
    end

    def fact_type(name, value)
      defined_readings, *clauses = value
      #p defined_readings
      #p clauses

      # We have to handle all fact clauses one way, conditions another:
      fact_clauses = defined_readings +
        clauses.select{|c| c[0] == :fact_clause }

      find_all_defined_roles(fact_clauses)

      # Process all fact invocations in both the defined_readings and the clauses:
      fact_clauses.each{|r| clause(r) }

      # REVISIT: Check that all defined readings have the same set of players
      debug "Defined readings: "+defined_readings.inspect
      players = defined_readings[0][2].map{|w| Hash === w ? w[:player] : nil }.compact.sort
      1.upto(defined_readings.size-1){|i|
          these_players = defined_readings[i][2].map{|w| Hash === w ? w[:player] : nil }.compact.sort
          if these_players != players
            # REVISIT: This will be an exception.
            debug "All readings for a new fact type definition must have the same players" do
              debug "Role players for first reading are: "+players.inspect
              debug "Role players for this reading: "+these_players.inspect
            end
          end
        }

      debug "Fact derivation clauses: "+clauses.pretty_inspect if clauses.size > 0

      define_fact_type(name, defined_readings, clauses)
    end

    def reset_defined_roles
      @local_roles = {}
      @local_forms = {}
      @local_forms_by_word = {}
    end

    # Extract any role names into @local_roles and
    # any defined adjectival forms into @local_forms (also indexed by word)
    def find_all_defined_roles(fact_clauses)
      debug "Search fact readings for role names:" do
        fact_clauses.each{|r| find_defined_roles(r[2]) }
        debug "Role names: "+ @local_roles.inspect if @local_roles.size > 0
      end
    end

    def find_defined_roles(reading)
      reading.each { |role|
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
        }
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
    #   :quantifier
    #   :leading_adjective
    #   :words
    #   :trailing_adjective
    #   :function
    #   :role_name
    #   :restriction
    #   :literal
    #
    # The interesting one here is :words, which might contain:
    # - linking words (e.g. "has", "is" "of"),
    # - adjectives
    # - role players (either type names, or role names from "(as role_name)").
    # We must sift these three classes of words. In the case of both adjectives
    # and role names, these might be defined in this query or in the fact types
    # that are being invoked.
    # 
    # Role names cannot conflict with type names in the name space of this
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
      roles.replace(roles.inject([]){|new_roles, role|
          words = role[:words]
          role.delete(:words)

          # If we have a quantifier or a leading adjective, we handle it differently.
          # In this case the leading words up to the player get added to a leading
          # adjectives array.
          la = role[:leading_adjective]
          role[:leading_adjective] = [la] if (la)   # Make it an array
          quant = role[:quantifier]
          role[:leading_adjective] ||= [] if quant      # Start an empty array
          la = role[:leading_adjective]
          ta = role[:trailing_adjective]
          role[:trailing_adjective] = Array(ta) if ta

          new_role = nil
          possible_extra_trailing_adjectives = []
          words.each{|w|
              local_role = @local_roles && @local_roles[w]
              if (local_role || type_by_name(w))
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

          new_roles
        }
      )
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
=end

  end

  Polyglot.register('cql', CQLParser)
end
