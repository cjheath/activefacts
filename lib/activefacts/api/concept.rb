#
# The ActiveFacts Runtime API Concept class
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
module ActiveFacts
  module API
    module Vocabulary; end

    module Concept
      def vocabulary
        modspace        # The module that contains this concept.
      end

      # Each Concept maintains a list of the Roles it plays:
      def roles(name = nil)
        unless instance_variable_defined? "@roles"
          @roles = RoleCollection.new     # Initialize and extend without warnings.
        end
        case name
        when nil
          @roles
        when Symbol, String
          r = @roles[name.to_sym]
          # REVISIT: Search other supertypes as well:
          return superclass.roles(name) rescue nil unless r
          player = r.player
          # We don't force the role to be bound yet; it's up to callers to bind it if necessary
          player = r.resolve_player(vocabulary) rescue player unless Class === player
          r
        else
          nil
        end
      end

      # Define a unary fact type attached to this concept
      def maybe(role_name)
        realise_role(roles[role_name] = Role.new(TrueClass, nil, role_name))
      end

      # Define a binary fact type joning this concept to another,
      # with a uniqueness constraint only on this concept's role.
      def has_one(*args)
        role_name, related, mandatory, related_role_name = extract_binary_params(false, args)
        define_binary_fact_type(false, role_name, related, mandatory, related_role_name)
      end

      # Define a binary fact type joning this concept to another,
      # with uniqueness constraints in both directions
      def one_to_one(*args)
        role_name, related, mandatory, related_role_name =
          extract_binary_params(true, args)
        define_binary_fact_type(true, role_name, related, mandatory, related_role_name)
      end

      # Access supertypes or add new supertypes
      def supertypes(*concepts)
        class_eval do
          @supertypes ||= []
          concepts.each do |concept|
            case concept
            when Class
              @supertypes << concept
            when Symbol
              @supertypes << (concept = vocabulary.const_get(concept.to_s.camelcase))
            else
              raise "Illegal supertype #{concept.inspect} for #{self.class.basename}"
            end

            # Realise the roles (create accessors) of this supertype.
            # REVISIT: The existing accessors at the other end will need to allow this class as role player
            # REVISIT: Need to check all superclass roles recursively, unless we hit a common supertype
            realise_roles(concept)
          end
          [superclass, *@supertypes]
        end
      end

      # Every new role added or inherited comes through here:
      def realise_role(role)
        if (!role.counterpart)
          # Unary role
          define_unary_role_accessor(role)
        elsif (role.unique)
          define_single_role_accessor(role, role.counterpart.unique)
        else
          define_array_role_accessor(role)
        end
      end

      # REVISIT: Use method_missing to catch all_some_role_by_other_role_and_third_role, to sort_by those roles?

      private

      # Realise all the roles of a concept on this concept, used when a supertype is added:
      def realise_roles(concept)
        concept.roles.each do |role_name, role|
          realise_role(role)
        end
      end

      # Shared code for both kinds of binary fact type (has_one and one_to_one)
      def define_binary_fact_type(one_to_one, role_name, related, mandatory, related_role_name)
        # puts "#{self}.#{role_name} is to #{related.inspect}, #{mandatory ? :mandatory : :optional}, related role is #{related_role_name}"

        roles[role_name] = role = Role.new(related, nil, role_name, mandatory)

        # There may be a forward reference here where role_name is a Symbol,
        # and the block runs later when that Symbol is bound to the concept.
        when_bound(related, self, role_name, related_role_name) do |target, definer, role_name, related_role_name|
          if (one_to_one)
            target.roles[related_role_name] = role.counterpart = Role.new(definer, role, related_role_name, false)
          else
            target.roles[related_role_name] = role.counterpart = Role.new(definer, role, related_role_name, false, false)
          end
          #puts "Realising role pair #{definer.basename}.#{role_name} <-> #{target.basename}.#{related_role_name}"
          realise_role(role)
          target.realise_role(role.counterpart)
        end
      end

      def define_unary_role_accessor(role)
        # puts "Defining #{basename}.#{role_name} as unary"
        class_eval do
          define_method "#{role.name}=" do |value|
            #puts "Setting #{self.class.name} #{object_id}.@#{role.name} to #{(value ? true : nil).inspect}"
            instance_variable_set("@#{role.name}", value ? true : nil)
            # REVISIT: Provide a way to find all instances playing/not playing this role
            # Analogous to true.all_thing_by_role_name...
          end
        end
        define_single_role_getter(role)
      end

      def define_single_role_getter(role)
        class_eval do
          define_method role.name do
            instance_variable_get("@#{role.name}") rescue nil
          end
        end
      end

      # REVISIT: Add __add_to(constellation) and __remove(constellation) here?
      def define_single_role_accessor(role, one_to_one)
        # puts "Defining #{basename}.#{role.name} to #{role.player.basename} (#{one_to_one ? "assigning" : "populating"} #{role.counterpart.name})"
        define_single_role_getter(role)

        if (one_to_one)
          # This gets called to assign nil to the related role in the old correspondent:
          # value is included here so we can check that the correct value is being nullified, if necessary
          nullify_reference = lambda{|from, role_name, value| from.send("#{role_name}=".to_sym, nil) }

          # This gets called to replace an old single value for a new one in the related role of a new correspondent
          assign_reference = lambda{|from, role_name, old_value, value| from.send("#{role_name}=".to_sym, value) }

          define_single_role_setter(role, nullify_reference, assign_reference)
        else
          # This gets called to delete this object from the role value array in the old correspondent
          delete_reference = lambda{|from, role_name, value| from.send(role_name).__delete(value) }

          # This gets called to replace an old value by a new one in the related role value array of a new correspondent
          replace_reference = lambda{|from, role_name, old_value, value| 
              array = from.send(role_name)
              array.__replace(array - [old_value].compact + [value])
            }

          define_single_role_setter(role, delete_reference, replace_reference)
        end
      end

      def define_single_role_setter(role, deassign_old, assign_new)
        class_eval do
          define_method "#{role.name}=" do |value|
            role_var = "@#{role.name}"
            #puts "Assigning #{self}.#{role.name} to #{value}, value will be added/assigned to #{role.counterpart.name}"

            # If role.player isn't bound to a class yet, bind it.
            role.resolve_player(self.class.vocabulary) unless Class === role.player

            # Get old value, and jump out early if it's unchanged:
            old = instance_variable_get(role_var) rescue nil
            return if old == value        # Occurs during one_to_one assignment, for example

            # Create a value instance we can hack if the value isn't already in this constellation
            # This throws an exception if the value instance can't be created.
            # REVISIT: if this object is in a constellation, the value must be also. Perhaps the constellation should be called here?
            value = self.class.vocabulary.adopt(role.player, constellation, value) if value
            return if old == value        # Occurs when same value is assigned

            # REVISIT: Defend against changing identifying roles, and decide what to do.

            # puts "Setting binary #{role_var} to #{value.verbalise}"
            instance_variable_set(role_var, value)

            # De-assign/remove "self" at the old other end too:
            deassign_old.call(old, role.counterpart.name, self) if old

            # Assign/add "self" at the other end too:
            assign_new.call(value, role.counterpart.name, old, self) if value
          end
        end
      end

      def define_array_role_accessor(role)
        class_eval do
          define_method "#{role.name}" do
            unless (r = instance_variable_get(role_var = "@#{role.name}") rescue nil)
              r = instance_variable_set(role_var, RoleValueArray.new)
            end
            # puts "fetching #{self.class.basename}.#{role.name} array, got #{r.class}, first is #{r[0] ? r[0].verbalise : "nil"}"
            r
          end
        end
      end

      # Extract the parameters to a role definition and massage them into the right shape.
      #
      # This function returns an array:
      # [ role_name,
      # related,
      # mandatory,
      # related_role_name ]
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
      def extract_binary_params(one_to_one, args)
        # Params:
        #   role_name (Symbol)
        #   other player (Symbol or Class)
        #   mandatory (:mandatory)
        #   other end role name if any (Symbol),
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
          related_role_name.to_sym 
        ]
      end

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
