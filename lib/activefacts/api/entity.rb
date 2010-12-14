#
#       ActiveFacts Runtime API
#       Entity class (a mixin module for the class Class)
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
module ActiveFacts
  module API
    # An Entity type is any ObjectType that isn't a value type.
    # All Entity types must have an identifier made up of one or more roles.
    module Entity
      include Instance

      # Assign the identifying roles to initialise a new Entity instance.
      # The role values are asserted in the constellation first, so you
      # can pass bare values (array, string, integer, etc) for any role
      # whose instances can be constructed using those values.
      #
      # A value must be provided for every identifying role, but if the
      # last argument is a hash, they may come from there.
      #
      # Any additional (non-identifying) roles may also be passed in the final hash.
      def initialize(*args)
        super(args)
        klass = self.class
        hash = {}
        hash = args.pop.clone if Hash === args[-1]

        # Pick any missing identifying roles out of the hash if possible:
        while args.size < (ir = klass.identifying_role_names).size
          value = hash[role = ir[args.size]]
          hash.delete(role)
          args.push value
        end

        # If one arg is expected but more are passed, they might be the args for the object that plays the identifying role:
        args = [args] if klass.identifying_role_names.size == 1 && args.size > 1

        # This should now only occur when there are too many args passed:
        raise "Wrong number of parameters to #{klass}.new, " +
            "expect (#{klass.identifying_role_names*","}) " +
            "got (#{args.map{|a| a.to_s.inspect}*", "})" if args.size != klass.identifying_role_names.size

        # Assign the identifying roles in order, then the other roles passed as a hash:
        (klass.identifying_role_names.zip(args) + hash.entries).each do |role_name, value|
          role = klass.roles(role_name)
          send("#{role_name}=", value)
        end
      end

      def inspect #:nodoc:
        "\#<#{
          self.class.basename
        }:#{
          object_id
        }#{
          constellation ? " in #{constellation.inspect}" : ""
        } #{
          # REVISIT: Where there are one-to-one roles, this cycles
          self.class.identifying_role_names.map{|role| "@#{role}="+send(role).inspect }*" "
        }>"
      end

      # When used as a hash key, the hash key of this entity instance is calculated
      # by hashing the values of its identifying roles
      def hash
        self.class.identifying_role_names.map{|role|
            instance_variable_get("@#{role}")
          }.inject(0) { |h,v|
            h ^= v.hash
            h
          }
      end

      # When used as a hash key, this entity instance is compared with another by
      # comparing the values of its identifying roles
      def eql?(other)
        return false unless self.class == other.class
        self.class.identifying_role_names.each{|role|
            return false unless send(role).eql?(other.send(role))
          }
        return true
      end

      # Verbalise this entity instance
      def verbalise(role_name = nil)
        "#{role_name || self.class.basename}(#{
          self.class.identifying_role_names.map{|role_sym|
              value = send(role_sym)
              role_name = self.class.roles(role_sym).name.to_s.camelcase
              value ? value.verbalise(role_name) : "nil"
            }*", "
        })"
      end

      # Return the array of the values of this entity instance's identifying roles
      def identifying_role_values
        self.class.identifying_role_names.map{|role|
            send(role)
          }
      end

      # All classes that become Entity types receive the methods of this class as class methods:
      module ClassMethods
        include Instance::ClassMethods

        # Return the array of Role objects that define the identifying relationships of this Entity type:
        def identifying_role_names
          @identifying_role_names ||= []
        end

        def identifying_roles
          debug :persistence, "Identifying roles for #{basename}" do
            @identifying_role_names.map{|name|
              role = roles[name] || (!superclass.is_entity_type || superclass.roles[name])
              debug :persistence, "#{name} -> #{role ? "found" : "NOT FOUND"}"
              role
            }
          end
        end

        # Convert the passed arguments into an array of Instance objects that can identify an instance of this Entity type:
        def identifying_role_values(*args)
          #puts "Getting identifying role values #{identifying_role_names.inspect} of #{basename} using #{args.inspect}"

          # If the single arg is an instance of the correct class or a subclass,
          # use the instance's identifying_role_values
          if (args.size == 1 and
              (arg = args[0]).is_a?(self))       # REVISIT: or a secondary supertype
            arg = arg.__getobj__ if RoleProxy === arg
            return arg.identifying_role_values
          end

          ir = identifying_role_names
          args, arg_hash = ActiveFacts::extract_hash_args(ir, args)

          if args.size > ir.size
            raise "You've provided too many values for the identifier of #{basename}, which expects (#{ir*', '})"
          end

          role_args = ir.map{|role_sym| roles(role_sym)}.zip(args)
          role_args.map do |role, arg|
            #puts "Getting identifying_role_value for #{role.counterpart_object_type.basename} using #{arg.inspect}"
            next !!arg unless role.counterpart  # Unary
            arg = arg.__getobj__ if RoleProxy === arg
            if arg.is_a?(role.counterpart_object_type)              # REVISIT: or a secondary supertype
              # Note that with a secondary supertype, it must still return the values of these identifying_role_names
              next arg.identifying_role_values
            end
            if arg == nil # But not false
              if role.mandatory
                raise "You must provide a #{role.counterpart_object_type.name} to identify a #{basename}"
              end
            else
              role.counterpart_object_type.identifying_role_values(*arg)
            end
          end
        end

        def assert_instance(constellation, args) #:nodoc:
          # Build the key for this instance from the args
          # The key of an instance is the value or array of keys of the identifying values.
          # The key values aren't necessarily present in the constellation, even after this.
          key = identifying_role_values(*args)

          # Find and return an existing instance matching this key
          instances = constellation.instances[self]   # All instances of this class in this constellation
          instance = instances[key]
          # DEBUG: puts "assert #{self.basename} #{key.inspect} #{instance ? "exists" : "new"}"
          return instance, key if instance      # A matching instance of this class

          # Now construct each of this object's identifying roles
          ir = identifying_role_names
          args, arg_hash = ActiveFacts::extract_hash_args(ir, args)
          role_values = ir.map{|role_sym| roles(role_sym)}.zip(args)
          key = []    # Gather the actual key (AutoCounters are special)
          values = role_values.map do |role, arg|
              if !arg
                value = role_key = nil          # No value
              elsif !role.counterpart
                value = role_key = !!arg        # Unary
              elsif arg.is_a?(role.counterpart_object_type)      # REVISIT: or a secondary supertype
                arg = arg.__getobj__ if RoleProxy === arg
                raise "Connecting values across constellations" unless arg.constellation == constellation
                value, role_key = arg, arg.identifying_role_values
              else
                value, role_key = role.counterpart_object_type.assert_instance(constellation, Array(arg))
              end
              key << role_key
              value
            end
          values << arg_hash if arg_hash and !arg_hash.empty?

          #puts "Creating new #{basename} using #{values.inspect}"
          instance = new(*values)

          # Make the new entity instance a member of this constellation:
          instance.constellation = constellation
          return *index_instance(instance, key, ir)
        end

        def index_instance(instance, key = nil, key_roles = nil) #:nodoc:
          # Derive a new key if we didn't receive one or if the roles are different:
          unless key && key_roles && key_roles == identifying_role_names
            key = (key_roles = identifying_role_names).map do |role_name|
              instance.send role_name
            end
          end

          # Index the instance for this class in the constellation
          instances = instance.constellation.instances[self]
          instances[key] = instance
          # DEBUG: puts "indexing entity #{basename} using #{key.inspect} in #{constellation.object_id}"

          # Index the instance for each supertype:
          supertypes.each do |supertype|
            supertype.index_instance(instance, key, key_roles)
          end

          return instance, key
        end

        # A object_type that isn't a ValueType must have an identification scheme,
        # which is a list of roles it plays. The identification scheme may be
        # inherited from a superclass.
        def initialise_entity_type(*args) #:nodoc:
          #puts "Initialising entity type #{self} using #{args.inspect}"
          @identifying_role_names = superclass.identifying_role_names if superclass.is_entity_type
          # REVISIT: @identifying_role_names here are the symbols passed in, not the Role objects we should use.
          # We'd need late binding to use Role objects...
          @identifying_role_names = args if args.size > 0 || !@identifying_role_names
        end

        def inherited(other) #:nodoc:
          other.identified_by *identifying_role_names
          subtypes << other unless subtypes.include? other
          #puts "#{self.name} inherited by #{other.name}"
          vocabulary.__add_object_type(other)
        end

        # verbalise this object_type
        def verbalise
          "#{basename} is identified by #{identifying_role_names.map{|role_sym| role_sym.to_s.camelcase}*" and "};"
        end
      end

      def Entity.included other #:nodoc:
        other.send :extend, ClassMethods

        # Register ourselves with the parent module, which has become a Vocabulary:
        vocabulary = other.modspace
        # puts "Entity.included(#{other.inspect})"
        unless vocabulary.respond_to? :object_type  # Extend module with Vocabulary if necessary
          vocabulary.send :extend, Vocabulary
        end
        vocabulary.__add_object_type(other)
      end
    end
  end
end
