#
# The ActiveFacts Runtime API Concept class
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
module ActiveFacts
  module API
    module Vocabulary; end

    # REVISIT: Perhaps I should use an enumerator here instead,
    # and just find a way to handle replace and delete?
    #
    # A ValueArray is an array with all mutating methods hidden.
    # We use these for the "many" side of a 1:many relationship.
    # Only "replace" and "delete" are actually used (so far!).
    # Perhaps sort! is innocuous and can remain?
    class ValueArray < Array
      [ :"<<", :"[]=", :clear, :collect!, :compact!, :concat, :delete,
        :delete_at, :delete_if, :fill, :flatten!, :insert, :map!, :pop,
        :push, :reject!, :replace, :reverse!, :shift, :shuffle!, :slice!,
        :sort!, :uniq!, :unshift
      ].each{|s|
          begin
            alias_method("__#{s}", s)
          rescue NameError  # shuffle! is in 1.9 only
          end
        }
    end

    module Concept
      def vocabulary
        modspace        # The module that contains this concept.
      end

      # Each Concept maintains a list of the Roles it plays:
      def roles(name = nil)
        unless instance_variable_defined? "@roles"
          @roles = {}     # Initialize and extend without warnings.
          def @roles.verbalise
            keys.sort_by(&:to_s).inspect
          end
        end
        case name
        when nil
          @roles
        when Numeric
          raise "Can't index roles by number"
        when Symbol, String
          r = @roles[name.to_sym]
          unless r
            return nil unless superclass.respond_to?(:roles)
            return superclass.roles(name)
          end
          player = r.player
          r.resolve_player(vocabulary) if Symbol === player
          r
        else
          nil
        end
      end

      def maybe(role_name)
        roles[role_name] = Role.new(TrueClass, true, role_name)
        # puts "Defining #{basename}.#{role_name} as unary"
        class_eval do
          role_var = "@#{role_name}"
          define_method "#{role_name}=" do |value|
            #puts "Setting #{self.class.name} #{object_id}.#{role_var} to #{(value ? true : nil).inspect}"
            instance_variable_set(role_var, value ? true : nil)
            # REVISIT: Provide a way to find all instances playing/not playing this role
            # Analogous to true.all_thing_by_role_name...
          end
          define_method "#{role_name}" do
            instance_variable_get(role_var)
          end
        end
      end

      def has_one(*args)
        role_name, related, mandatory, related_role_name, reading =
          binary_params(false, args)
        __binary(false, role_name, related, mandatory, related_role_name, reading)
      end

      def one_to_one(*args)
        role_name, related, mandatory, related_role_name, reading =
          binary_params(true, args)
        __binary(true, role_name, related, mandatory, related_role_name, reading)
      end

      def __binary(one_to_one, role_name, related, mandatory, related_role_name, reading)
        # puts "#{self}.#{role_name} is to #{related.inspect}, #{mandatory ? :mandatory : :optional}, related role is #{related_role_name}, reading=#{reading.inspect}"

        __single(role_name, related, related_role_name, mandatory, one_to_one)

        when_bound(related, self, role_name, related_role_name) do |target, definer, role_name, related_role_name|
          if (one_to_one)
            target.__single(related_role_name, definer, role_name, false, one_to_one)
          else
            target.__multiple(related_role_name, definer, role_name)
          end
        end
      end

      # An objectified fact type supports readings, which may contain:
      # "/", separating multiple alternate readings
      # ":concept", indicating that the Concept plays this role
      def reading(*args)
        # REVISIT: No support for readings yet.
        # puts "#{self.inspect}#reading: #{args.inspect}"
      end

      # Define accessor methods for this role name, which should be assigned an object of the indicated class
      def __single(role_name, klass, related_role_name, mandatory = false, one_to_one = false)
        raise "not sym" unless Symbol === role_name
        roles[role_name] = Role.new(klass, true, role_name, mandatory)

        # puts "Defining #{basename}.#{role_name} to #{klass.basename} (#{one_to_one ? "assigning" : "populating"} #{related_role_name})"
        class_eval do
          role_var = "@#{role_name}"

          # Define the getter
          define_method role_name do
            instance_variable_defined?(role_var) ? instance_variable_get(role_var) : nil
          end

          # Define the setter
          define_method "#{role_name}=" do |value|
            #puts "Assigning #{self}.#{role_name} to #{value}, value will be added/assigned to #{related_role_name}"

            unless Class === klass      # klass wasn't bound, find what class the value should be:
              role = self.class.roles(role_name)
              raise "#{role_name} is not a role of #{self.class.name}" unless role
              unless Class === (klass = role.resolve_player(vocab = self.class.vocabulary))
                raise "Role #{role_name} does not resolve to any existing class in vocabulary #{vocabulary.name}"
              end
            end

            # Get old value, and jump out early if it's already set
            old = instance_variable_defined?(role_var) ? instance_variable_get(role_var) : nil
            return if old == value        # Occurs during one_to_one assignment, for example

            # Create a value instance we can hack if the value isn't already in this constellation
            value = self.class.vocabulary.adopt(klass, constellation, value) if value
            return if old == value        # Occurs when same value is assigned

            # puts "Setting binary #{role_var} to #{value.verbalise}"
            instance_variable_set(role_var, value)

            # De-assign/remove "self" at the old other end too:
            if old
              if one_to_one
                old.send("#{related_role_name}=".to_sym, nil)
              else
                old.send(related_role_name).__delete(self)
              end
            end

            # Assign/add "self" at the other end too:
            if value
              if one_to_one
                value.send("#{related_role_name}=".to_sym, self)
              else
                # puts "Other end's value #{klass.basename}.#{related_role_name} in #{self.class.basename}.#{role_name}= is #{value.class.basename}, expected #{klass.basename}"
                begin
                  array = value.send(related_role_name)
                rescue => e
                  puts "Error #{e} getting MANY array from #{self.class} for '#{value.inspect}' role #{related_role_name}"
                end
                array.__replace(array - [old].compact + [self])
                # REVISIT: It's possible that "old" now has no roles except its identifier, and if not independant, can be removed.
              end
            end
          end
        end
      end

      # REVISIT: Use method_missing to catch all_some_role_by_other_role_and_third_role, to sort_by those roles?

      def __multiple(role_name, klass, single_role_name)
        raise "__multiple(#{role_name.class} #{role_name.inspect}) - Symbol expected" unless Symbol === role_name
        roles[role_name] = Role.new(klass, false, role_name, false)

        # puts "Defining #{basename}.#{role_name} to array of #{klass.basename} (via #{single_role_name})"

        class_eval do
          role_var = "@#{role_name}"
          define_method "#{role_name}" do
            unless (r = instance_variable_defined?(role_var) && instance_variable_get(role_var))
              (r = instance_variable_set(role_var, ValueArray.new))
            end
            # puts "fetching #{self.class.basename}.#{role_name} array, got #{r.class}, first is #{r[0] ? r[0].verbalise : "nil"}"
            r
          end
        end
      end


      private

      # Extract the parameters to a role definition and massage them into the right shape.
      #
      # This function returns an array:
      # [ role_name,
      # related,
      # mandatory,
      # related_role_name,
      # reading ]
      #
      # Role naming rule:
      #   "all_" if there may be more than one (only ever on related end)
      #   Role Name:
      # If a role name is defined at this end:
      #   Role Name
      # else:
      #   Leading Adjective
      #   Role player name (not role name)
      #   Trailing Adjective
      # "_by_<other_role_name>" if other_role_name != this role player's name, and not other_player_this_player
      def binary_params(one_to_one, args)
        # Params:
        #   role_name (Symbol)
        #   other player (Symbol or Class)
        #   mandatory (:mandatory)
        #   other end role name if any (Symbol),
        #   reading
        role_name = nil
        related = nil
        mandatory = false
        related_role_name = nil
        role_player = self.basename.snakecase

        # Get the role name first:
        case a = args.shift
        when Symbol, String
          role_name = a.to_sym
        when Class
          role_name = a.name.snakecase.to_sym
        else
          raise "Illegal first parameter to role: #{a.inspect}"
        end
        # puts "role_name = #{role_name.inspect}"

        # The related class might be forward-referenced, so handle a Symbol/String instead of a Class.
        case related_name = a = args.shift
        when Class
          related = a
          related_name = a.basename
        when :mandatory, Numeric
          args.unshift(a)       # Oops, undo.
          related_name =
          related = role_name
        when Symbol, String
          related = a
        else
          related = role_name
        end
        related_name ||= role_name
        related_name = related_name.to_s.snakecase

        # resolve the Symbol to a Class now if possible:
        resolved = vocabulary.concept(related) rescue nil
        related = resolved if resolved
        # puts "related = #{related.inspect}"

        if args[0] == :mandatory
          mandatory = true
          args.shift
        end

        if Symbol == args[0]
          related_role_name = args.shift
        end

        reading = args[0]

        # Avoid a confusing mismatch:
        # Note that if you have a role "supervisor" and a sub-class "Supervisor", this'll bitch.
        if (Class === related && (indicated = vocabulary.concept(role_name)) && indicated != related)
          raise "Role name #{role_name} indicates a different player #{indicated} than specified"
        end

        # puts "Calculating related method name for related_role_name=#{related_role_name.inspect}, related_name=#{related_name.inspect}, role_player=#{role_player.inspect}, role_name=#{role_name.inspect}:"

        related_role_name ||= (role_player || "")  # REVISIT: Add adjectives here
        unless one_to_one
          related_role_name = "all_#{role_player}" +
            if related_name == role_name.to_s || role_name.to_s == "#{role_player}_#{related_name}"
              ""
            else
              "_by_#{role_name}"
            end
        end

        [ role_name,
          related,
          mandatory,
          related_role_name.to_sym,
          reading
        ]

=begin
        #puts "looking for adjectives for #{related.to_s} in #{role_name}" if related
        # Detect adjectives in the role_name
        if (related && (related_name = related.basename).length != role_name.to_s.length)
          if role_name[-related_name.length..-1].downcase == related_name.downcase
            # role_name has related_name as a suffix
            leading_adjective = role_name[0..-related_name.length-1]
            leading_adjective.chop! if leading_adjective[-1,1] == "_"
            puts "Role #{role_name} is #{leading_adjective}-#{related_name}; store adjectives"
          elsif role_name[0, related_name.length]
            trailing_adjective = role_name[related_name.length..-1]
            trailing_adjective.shift if trailing_adjective[0,1] == '_'
            puts "Role #{role_name} is #{related_name}-#{trailing_adjective}; store adjectives"
          elsif (role_name.downcase != related_name.downcase)
            if @vocabulary.concept(role_name.camelcase(true))
              raise "Role name #{role_name} may be name of existing concept unless that concept plays that role"
            end
          end
        end
=end
      end

      def inherited(other)
        puts "REVISIT: ValueType #{self} < #{self.superclass} was inherited by #{other}; not implemented"
        # Copy the type parameters here, etc?
      end

      class Role
        attr_accessor :name
        attr_accessor :unary
        attr_accessor :player           # May be a Symbol, which will be converted to a Class/Concept
        attr_accessor :mandatory
        attr_accessor :value_restriction

        def initialize(player, unary, name, mandatory = false)
          @player = player
          @unary = unary
          @name = name
          @mandatory = mandatory
        end

        def resolve_player(vocabulary)
          return @player if Class === @player   # Done already
          klass = vocabulary.concept(@player)   # Trigger the binding
          @player = klass if klass              # Memoize a successful result
          @player
        end
      end

      private

      def when_bound(concept, *args, &block)
        case concept
        when Class
          block.call(concept, *args)    # Execute block in the context of the concept
        when Symbol
          vocabulary.__delay(concept.to_s.camelcase(true), args, &block)
        when String     # Arrange for this to happen later
          vocabulary.__delay(concept, args, &block)
        else
          raise "Delayed binding not possible for #{concept.inspect}"
        end
      end
    end
  end
end
