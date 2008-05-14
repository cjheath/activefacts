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
        hash = args.pop if Hash === args[-1]

        # Pick any missing identifying_roles out of the hash if possible:
        while args.size < klass.identifying_roles.size
          value = hash[role = k.identifying_roles[args.size]]
          raise "To create a #{k} you must provide a #{role}" unless value
          hash.delete(role)
          args.push value
        end

        # This should now only occur when there are too many args passed:
        raise "Wrong number of parameters to #{klass}.new, " +
            "expect (#{klass.identifying_roles*","}) " +
            "got (#{args.map{|a| a.to_s.inspect}*", "})" if args.size != klass.identifying_roles.size

        # Assign the identifying roles in order, then the other roles passed as a hash:
        (klass.identifying_roles.zip(args) + hash.entries).each{|pair|
            role, value = *pair
            send("#{role}=", value)
          }
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

      module ClassMethods
        include Instance::ClassMethods

        # Entity class methods:
        def identifying_roles
          @identifying_roles ||= []
        end

        # A concept that isn't a ValueType must have an identification scheme,
        # which is a list of roles it plays. The identification scheme may be
        # inherited from a superclass.
        def initialise_entity_type(*args)
          # puts "Initialising entity type #{self}"
          @identifying_roles = superclass.identifying_roles if superclass.respond_to?(:identifying_roles)
          @identifying_roles = args if args.size > 0 || !@identifying_roles
        end

        def inherited(other)
          other.identified_by #identifying_roles
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
        unless vocabulary.respond_to? :concept
          vocabulary.send :extend, Vocabulary
        end
        vocabulary.add_concept(other)
      end
    end
  end
end
