#
#       ActiveFacts Runtime API
#       ObjectType (a mixin module for the class Class)
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#

module ActiveFacts
  module API
    module Vocabulary; end

    # ObjectType contains methods that are added as class methods to all Value and Entity classes.
    module ObjectType
      # What vocabulary (Ruby module) does this object_type belong to?
      def vocabulary
        modspace        # The module that contains this object_type.
      end

      # Each ObjectType maintains a list of the Roles it plays:
      def roles(name = nil)
        unless instance_variable_defined? "@roles"
          @roles = RoleCollection.new     # Initialize and extend without warnings.
        end
        case name
        when nil
          @roles
        when Symbol, String
          # Search this class then all supertypes:
          unless role = @roles[name.to_sym]
            role = nil
            supertypes.each do |supertype|
                r = supertype.roles(name) rescue nil
                next unless r
                role = r
                break
              end
          end
          raise "Role #{basename}.#{name} is not defined" unless role
          # Bind the role if possible, but don't require it:
          role.resolve_counterpart(vocabulary) rescue nil unless role.counterpart_object_type.is_a?(Class)
          role
        else
          nil
        end
      end

      # Define a unary fact type attached to this object_type; in essence, a boolean attribute.
      #
      # Example: maybe :is_ceo
      def maybe(role_name)
        realise_role(roles[role_name] = Role.new(self, TrueClass, nil, role_name))
      end

      # Define a binary fact type relating this object_type to another,
      # with a uniqueness constraint only on this object_type's role.
      # This method creates two accessor methods, one in this object_type and one in the other object_type.
      # * role_name is a Symbol for the name of the role (this end of the relationship)
      # Options contain optional keys:
      # * :class - A class name, Symbol or String naming a class, required if it doesn't match the role_name. Use a symbol or string if the class isn't defined yet, and the methods will be created later, when the class is first defined.
      # * :mandatory - if this role may not be NULL in a valid fact population, say :mandatory => true. Mandatory constraints are only enforced during validation (e.g. before saving).
      # * :counterpart - use if the role at the other end should have a name other than the default :all_<object_type> or :all_<object_type>\_as_<role_name>
      # * :reading - for verbalisation. Not used yet.
      # * :restrict - a list of values or ranges which this role may take. Not used yet.
      def has_one(role_name, options = {})
        role_name, related, mandatory, related_role_name = extract_binary_params(false, role_name, options)
        define_binary_fact_type(false, role_name, related, mandatory, related_role_name)
      end

      # Define a binary fact type joining this object_type to another,
      # with uniqueness constraints in both directions, i.e. a one-to-one relationship
      # This method creates two accessor methods, one in this object_type and one in the other object_type.
      # * role_name is a Symbol for the name of the role (this end of the relationship)
      # Options contain optional keys:
      # * :class - A class name, Symbol or String naming a class, required if it doesn't match the role_name. Use a symbol or string if the class isn't defined yet, and the methods will be created later, when the class is first defined.
      # * :mandatory - if this role may not be NULL in a valid fact population, say :mandatory => true. Mandatory constraints are only enforced during validation (e.g. before saving).
      # * :counterpart - use if the role at the other end should have a name other than the default :all_<object_type> or :all_<object_type>\_as_<role_name>
      # * :reading - for verbalisation. Not used yet.
      # * :restrict - a list of values or ranges which this role may take. Not used yet.
      def one_to_one(role_name, options = {})
        role_name, related, mandatory, related_role_name =
          extract_binary_params(true, role_name, options)
        define_binary_fact_type(true, role_name, related, mandatory, related_role_name)
      end

      # Access supertypes or add new supertypes; multiple inheritance.
      # With parameters (Class objects), it adds new supertypes to this class. Instances of this class will then have role methods for any new superclasses (transitively). Superclasses must be Ruby classes which are existing ObjectTypes.
      # Without parameters, it returns the array of ObjectType supertypes (one by Ruby inheritance, any others as defined using this method)
      def supertypes(*object_types)
        class_eval do
          @supertypes ||= []
          all_supertypes = supertypes_transitive
          object_types.each do |object_type|
            next if all_supertypes.include? object_type
            case object_type
            when Class
              @supertypes << object_type
            when Symbol
              # No late binding here:
              @supertypes << (object_type = vocabulary.const_get(object_type.to_s.camelcase))
            else
              raise "Illegal supertype #{object_type.inspect} for #{self.class.basename}"
            end

            # Realise the roles (create accessors) of this supertype.
            # REVISIT: The existing accessors at the other end will need to allow this class as role counterpart
            # REVISIT: Need to check all superclass roles recursively, unless we hit a common supertype
            #puts "Realising object_type #{object_type.name} in #{basename}"
            realise_supertypes(object_type, all_supertypes)
          end
          [(superclass.vocabulary && superclass rescue nil), *@supertypes].compact
        end
      end

      # Return the array of all ObjectType supertypes, transitively.
      def supertypes_transitive
        class_eval do
          supertypes = []
          supertypes << superclass if Module === (superclass.vocabulary rescue nil)
          supertypes += (@supertypes ||= [])
          supertypes.inject([]) {|a, t|
              next if a.include?(t)
              a += [t]
              a += t.supertypes_transitive rescue []
            }.uniq
        end
      end

      def subtypes
        @subtypes ||= []
      end

      # Every new role added or inherited comes through here:
      def realise_role(role) #:nodoc:
        #puts "Realising role #{role.counterpart_object_type.basename rescue role.counterpart_object_type}.#{role.name} in #{basename}"

        if (!role.counterpart)
          # Unary role
          define_unary_role_accessor(role)
        elsif (role.unique)
          define_single_role_accessor(role, role.counterpart.unique)
        else
          define_array_role_accessor(role)
        end
      end

      # REVISIT: Use method_missing to catch all_some_role_as_other_role_and_third_role, to sort_by those roles?

      def is_a? klass
        super || supertypes_transitive.include?(klass)
      end

      private

      def realise_supertypes(object_type, all_supertypes = nil)
        all_supertypes ||= supertypes_transitive
        s = object_type.supertypes
        #puts "realising #{object_type.basename} supertypes #{s.inspect} of #{basename}"
        s.each {|t|
            next if all_supertypes.include? t
            realise_supertypes(t, all_supertypes)
            t.subtypes << self
            all_supertypes << t
          }
        #puts "Realising roles of #{object_type.basename} in #{basename}"
        realise_roles(object_type)
      end

      # Realise all the roles of a object_type on this object_type, used when a supertype is added:
      def realise_roles(object_type)
        object_type.roles.each do |role_name, role|
          realise_role(role)
        end
      end

      # Shared code for both kinds of binary fact type (has_one and one_to_one)
      def define_binary_fact_type(one_to_one, role_name, related, mandatory, related_role_name)
        # puts "#{self}.#{role_name} is to #{related.inspect}, #{mandatory ? :mandatory : :optional}, related role is #{related_role_name}"

        raise "#{name} cannot have more than one role named #{role_name}" if roles[role_name]
        roles[role_name] = role = Role.new(self, related, nil, role_name, mandatory)

        # There may be a forward reference here where role_name is a Symbol,
        # and the block runs later when that Symbol is bound to the object_type.
        when_bound(related, self, role_name, related_role_name) do |target, definer, role_name, related_role_name|
          if (one_to_one)
            target.roles[related_role_name] = role.counterpart = Role.new(target, definer, role, related_role_name, false)
          else
            target.roles[related_role_name] = role.counterpart = Role.new(target, definer, role, related_role_name, false, false)
          end
          role.counterpart_object_type = target
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
            # Analogous to true.all_thing_as_role_name...
          end
        end
        define_single_role_getter(role)
      end

      def define_single_role_getter(role)
        class_eval do
          define_method role.name do |*a|
            raise "Parameters passed to #{self.class.name}\##{role.name}" if a.size > 0
            i = instance_variable_get("@#{role.name}") rescue nil
            i ? RoleProxy.new(role, i) : i
            i
          end
        end
      end

      # REVISIT: Add __add_to(constellation) and __remove(constellation) here?
      def define_single_role_accessor(role, one_to_one)
        # puts "Defining #{basename}.#{role.name} to #{role.counterpart_object_type.basename} (#{one_to_one ? "assigning" : "populating"} #{role.counterpart.name})"
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
          delete_reference = lambda{|from, role_name, value| from.send(role_name).update(value, nil) }

          # This gets called to replace an old value by a new one in the related role value array of a new correspondent
          replace_reference = lambda{|from, role_name, old_value, value| 
              from.send(role_name).update(old_value, value)
            }

          define_single_role_setter(role, delete_reference, replace_reference)
        end
      end

      def define_single_role_setter(role, deassign_old, assign_new)
        class_eval do
          define_method "#{role.name}=" do |value|
            role_var = "@#{role.name}"

            # If role.counterpart_object_type isn't bound to a class yet, bind it.
            role.resolve_counterpart(self.class.vocabulary) unless role.counterpart_object_type.is_a?(Class)

            # Get old value, and jump out early if it's unchanged:
            old = instance_variable_get(role_var) rescue nil
            return if old == value        # Occurs during one_to_one assignment, for example

            value = role.adapt(constellation, value) if value
            return if old == value        # Occurs when same value is assigned

            # DEBUG: puts "assign #{self.class.basename}.#{role.name} <-> #{value.inspect}.#{role.counterpart.name}#{old ? " (was #{old.inspect})" : ""}"

            # REVISIT: A frozen-key solution could be used to allow changing identifying roles.
            # The key would be frozen, allowing indices and counterparts to de-assign,
            # but delay re-assignment until defrosted.
            # That would also allow caching the identifying_role_values, a performance win.

            # This allows setting and clearing identifying roles, but not changing them.
            raise "#{self.class.basename}: illegal attempt to modify identifying role #{role.name}" if role.is_identifying && value != nil && old != nil

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
              r = instance_variable_set(role_var, RoleValues.new)
            end
            # puts "fetching #{self.class.basename}.#{role.name} array, got #{r.class}, first is #{r[0] ? r[0].verbalise : "nil"}"
            r
          end
        end
      end

      # Extract the parameters to a role definition and massage them into the right shape.
      #
      # The first parameter, role_name, is mandatory. It may be a Symbol, a String or a Class.
      # New proposed input options:
      # :class => the related class (Class object or Symbol). Not allowed if role_name was a class.
      # :mandatory => true. There must be a related object for this object to be valid.
      # :counterpart => Symbol/String. The name of the counterpart role. Will be to_s.snakecase'd and maybe augmented with "all_" and/or "_as_<role_name>"
      # :reading => "forward/reverse". Forward and reverse readings. Must include MARKERS for the player names. May include adjectives. REVISIT: define MARKERS!
      # LATER:
      # :order => :local_role OR lambda{} (for sort_by)
      # :restrict => Range or Array of Range/value or respond_to?(include?)
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
      #   Role counterpart_object_type name (not role name)
      #   Trailing Adjective
      # "_as_<other_role_name>" if other_role_name != this role counterpart_object_type's name, and not other_player_this_player
      def extract_binary_params(one_to_one, role_name, options)
        # Options:
        #   other counterpart_object_type (Symbol or Class)
        #   mandatory (:mandatory)
        #   other end role name if any (Symbol),
        related = nil
        mandatory = false
        related_role_name = nil
        role_player = self.basename.snakecase

        role_name = a.name.snakecase.to_sym if Class === role_name
        role_name = role_name.to_sym

        # The related class might be forward-referenced, so handle a Symbol/String instead of a Class.
        related_name = options.delete(:class)
        case related_name
        when nil
          related = role_name # No :class provided, assume it matches the role_name
          related_name ||= role_name.to_s
        when Class
          related = related_name
          related_name = related_name.basename.to_s.snakecase
        when Symbol, String
          related = related_name
          related_name = related_name.to_s.snakecase
        else
          raise "Invalid type for :class option on :#{role_name}"
        end

        # resolve the Symbol to a Class now if possible:
        resolved = vocabulary.object_type(related) rescue nil
        #puts "#{related} resolves to #{resolved}"
        related = resolved if resolved
        # puts "related = #{related.inspect}"

        if options.delete(:mandatory) == true
          mandatory = true
        end

        related_role_name = related_role_name.to_s if related_role_name = options.delete(:counterpart)

        reading = options.delete(:reading)        # REVISIT: Implement verbalisation
        role_value_constraint = options.delete(:restrict)   # REVISIT: Implement role value constraints

        raise "Unrecognised options on #{role_name}: #{options.keys.inspect}" unless options.empty?

        # Avoid a confusing mismatch:
        # Note that if you have a role "supervisor" and a sub-class "Supervisor", this'll bitch.
        if (Class === related && (indicated = vocabulary.object_type(role_name)) && indicated != related)
          raise "Role name #{role_name} indicates a different counterpart object_type #{indicated} than specified"
        end

        # This code probably isn't as quick or simple as it could be, but it does work right,
        # and that was pretty hard, because the variable naming is all over the shop. Should fix
        # the naming first (here and in generate/oo.rb) then figure out how to speed it up.
        # Note that oo.rb names things from the opposite end, so you wind up in a maze of mirrors.
        other_role_method =
          (one_to_one ? "" : "all_") +
          (related_role_name || role_player)
        if role_name.to_s != related_name and
            (!related_role_name || related_role_name == role_player)
          other_role_method += "_as_#{role_name}"
        end
        #puts "On #{basename}: have related_role_name=#{related_role_name.inspect}, role_player=#{role_player}, role_name=#{role_name}, related_name=#{related_name.inspect} -> #{related_name}.#{other_role_method}"

        [ role_name,
          related,
          mandatory,
          other_role_method.to_sym 
        ]
      end

      def when_bound(object_type, *args, &block)
        case object_type
        when Class
          block.call(object_type, *args)    # Execute block in the context of the object_type
        when Symbol
          vocabulary.__delay(object_type.to_s.camelcase, args, &block)
        when String     # Arrange for this to happen later
          vocabulary.__delay(object_type, args, &block)
        else
          raise "Delayed binding not possible for #{object_type.class.name} #{object_type.inspect}"
        end
      end
    end
  end
end
