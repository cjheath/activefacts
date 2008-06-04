#
# The ActiveFacts Runtime API Entity class
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
# An Entity type is any Concept that isn't a value type.
# All Entity types must have an identifier made up of one or more roles.
#
module ActiveFacts
  module API
    module Entity
      include Instance

      # Entity instance methods:

      def initialize(*args)
        super(args)
        klass = self.class
        hash = {}
        hash = args.pop.clone if Hash === args[-1]

        # Pick any missing identifying_roles out of the hash if possible:
        while args.size < (ir = klass.identifying_roles).size
          value = hash[role = ir[args.size]]
          hash.delete(role)
          args.push value
        end

        # This should now only occur when there are too many args passed:
        raise "Wrong number of parameters to #{klass}.new, " +
            "expect (#{klass.identifying_roles*","}) " +
            "got (#{args.map{|a| a.to_s.inspect}*", "})" if args.size != klass.identifying_roles.size

        # Assign the identifying roles in order, then the other roles passed as a hash:
        (klass.identifying_roles.zip(args) + hash.entries).each do |role_name, value|
          role = klass.roles(role_name)
          send("#{role_name}=", value)
        end
      end

      def inspect
        "\#<#{
          self.class.basename
        }:#{
          object_id
        }#{
          constellation ? " in #{constellation.inspect}" : ""
        } #{
          # REVISIT: Where there are one-to-one roles, this cycles
          self.class.identifying_roles.map{|role| "@#{role}="+send(role).inspect }*" "
        }>"
      end

      def hash
        self.class.identifying_roles.map{|role|
            send role
          }.inject(0) { |h,v|
            h ^= v.hash
            h
          }
      end

      # To be equal as a hash key, must have same identifying role values
      def eql?(other)
        return false unless self.class == other.class
        self.class.identifying_roles.each{|role|
            return false unless send(role).eql?(other.send(role))
          }
        return true
      end

      # verbalise this entity
      def verbalise(role_name = nil)
        "#{role_name || self.class.basename}(#{
          self.class.identifying_roles.map{|role_sym|
              value = send(role_sym)
              role_name = self.class.roles(role_sym).name.to_s.camelcase(true)
              value ? value.verbalise(role_name) : "nil"
            }*", "
        })"
      end

      # An entity's key is the values of its identifying roles
      def identifying_role_values
        self.class.identifying_roles.map{|role|
            send(role)
          }
      end

      module ClassMethods
        include Instance::ClassMethods

        # Entity class methods:
        def identifying_roles
          @identifying_roles ||= []
        end

        def identifying_role_values(*args)
          #puts "Getting identifying role values #{identifying_roles.inspect} of #{basename} using #{args.inspect}"

          # If the single arg is an instance of the correct class or a subclass,
          # use the instance's identifying_role_values
          if (args.size == 1 and
              self === args[0])       # REVISIT: or a secondary supertype
            return args[0].identifying_role_values
          end

          ir = identifying_roles
          args, arg_hash = ActiveFacts::extract_hash_args(ir, args)
          unless args.size == ir.size
            raise "#{basename} requires all identifying values, you're missing #{ir[args.size..-1].map(&:to_sym)*', '}"
          end

          role_args = ir.map{|role_sym| roles(role_sym)}.zip(args)
          role_args.map do |role, arg|
            #puts "Getting identifying_role_value for #{role.player.basename} using #{arg.inspect}"
            next nil unless arg
            next !!arg unless role.counterpart  # Unary
            if role.player === arg              # REVISIT: or a secondary supertype
              # Note that with a secondary supertype, it must still return the values of these identifying_roles
              next arg.identifying_role_values
            end
            role.player.identifying_role_values(*arg)
          end
        end

        def assert_instance(constellation, args)
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
          ir = identifying_roles
          args, arg_hash = ActiveFacts::extract_hash_args(ir, args)
          role_values = ir.map{|role_sym| roles(role_sym)}.zip(args)
          key = []    # Gather the actual key (AutoCounters are special)
          values = role_values.map do |role, arg|
              if !arg
                value = role_key = nil          # No value
              elsif !role.counterpart
                value = role_key = !!arg        # Unary
              elsif role.player === arg         # REVISIT: or a secondary supertype
                raise "Connecting values across constellations" unless arg.constellation == constellation
                value, role_key = arg, arg.identifying_role_values
              else
                value, role_key = role.player.assert_instance(constellation, Array(arg))
              end
              key << role_key
              value
            end
          values << arg_hash if arg_hash and !arg_hash.empty?

          #puts "Creating new #{basename} using #{values.inspect}"
          instance = new(*values)

          # Make the new entity instance a member of this constellation:
          instance.constellation = constellation
          #puts "Indexed new #{basename} using #{key.inspect} on #{constellation.object_id}"
          # DEBUG: puts "indexing entity #{instance.class.basename} on #{key.inspect}"
          instances[key] = instance
          return instance, key
        end

        # A concept that isn't a ValueType must have an identification scheme,
        # which is a list of roles it plays. The identification scheme may be
        # inherited from a superclass.
        def initialise_entity_type(*args)
          #puts "Initialising entity type #{self} using #{args.inspect}"
          @identifying_roles = superclass.identifying_roles if superclass.respond_to?(:identifying_roles)
          # REVISIT: identifying_roles here are the symbols passed in, not the Role objects we should use:
          @identifying_roles = args if args.size > 0 || !@identifying_roles
        end

        def inherited(other)
          other.identified_by *identifying_roles
          vocabulary.add_concept(other)
        end

        # verbalise this concept
        def verbalise
          "#{basename} = entity type known by #{identifying_roles.map{|role_sym| role_sym.to_s.camelcase(true)}*" and "};"
        end
      end

      def Entity.included other
        other.send :extend, ClassMethods

        # Register ourselves with the parent module, which has become a Vocabulary:
        vocabulary = other.modspace
        unless vocabulary.respond_to? :concept  # Extend module with Vocabulary if necessary
          vocabulary.send :extend, Vocabulary
        end
        vocabulary.add_concept(other)
      end
    end
  end
end
