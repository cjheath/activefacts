#
# The ActiveFacts Runtime API Constellation class
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#
# A Constellation is a population of instances of the concept classes of a vocabulary.
# Every concept is either a value type or an entity type, and entity instances are
# uniquely identified by their identifying roles.
#
# A Constellation will never have more than one instance of a concept with the
# same identifying roles.
#
# A Constellation may or not be valid according to the vocabulary's constraints,
# but it may also represent a portion of a larger population (a database) with
# which it may be merged to form a valid population. In other words, an invalid
# Constellation may be invalid only because it only contains some of the facts.
#
module ActiveFacts
  class Constellation
    attr_reader :vocabulary
    attr_reader :query
    attr_reader :instances      # Can say c.instances[MyClass].each{|k, v| ... }
                                # Can also say c.MyClass.each{|k, v| ... }
                                # Create using c.MyClass(identifying_role_value, ...)
                                # REVISIT: Protect instances from modification?

    def initialize(vocabulary, query = nil)
      @vocabulary = vocabulary
      @instances = Hash.new{|h,k| h[k] = {} }
      @query = query
    end

    def inspect
      "Constellation:#{object_id}"
    end

    def delete(instance)
      # REVISIT: Need to search, as key values are gone already. Is there a faster way?
      @instances[instance.class].delete_if{|k,v| v == instance }
    end

    def method_missing(m, *args)
      if klass = @vocabulary.const_get(m)
        if args.size == 0
          @instances[klass]
        else
          # REVISIT: create the constructor method here instead?

          # REVISIT: Shouldn't determine existence by constructor arguments, but by comparison of the created object's identifying roles.

          # If the same object already exists in this constellation, re-use it.
          key = Kernel::Array(args.size > 1 ? args : args[0]).clone
          key.pop if Hash === Array(key)[-1]

          #print "class #{m} key=#{key.inspect} is "
          uncommitted = key == [:new]           # Occurs with AutoCounter
          instance = uncommitted ? nil : @instances[klass][key]
          # puts "Looked for #{klass} using #{key.inspect}, found #{instance.inspect}"

          if instance
            #puts "existing"
          else
            #puts "new"
            #puts "Making new #{klass}(#{args.map(&:inspect)*", "})"
            args = [self]+args unless klass.respond_to?(:__Is_A_Date) # Date arguments are special, can't add constellation
            begin
              instance = klass.send :new, *args
            rescue ArgumentError => e
              raise "Can't instantiate #{klass} using #{args.map(&:class)*", "}: #{e}"
            end

            # Register the new object in the hash of similar instances
            # print "Adding new instance #{instance.inspect} by #{key.inspect}"
            instance.constellation = self
            @instances[klass][uncommitted ? instance.object_id.to_s : key] = instance
          end
          instance
        end
      end
    end

    # Constellations verbalise all members of all classes in alphabetical order, showing non-identifying roles as well
    def verbalise
      "Constellation over #{vocabulary.name}:\n" +
      vocabulary.concept.keys.sort.map{|concept|
          klass = vocabulary.const_get(concept)

          # REVISIT: It would be better not to rely on the role name pattern here:
          single_roles, multiple_roles = klass.roles.keys.sort_by(&:to_s).partition{|r| r.to_s !~ /\Aall_/ }
          single_roles -= klass.identifying_roles if (klass.respond_to?(:identifying_roles))
          # REVISIT: Need to include superclass roles also.

          instances = send(concept.to_sym)
          next nil unless instances.size > 0
          "\tEvery #{concept}:\n" +
            instances.map{|instance|
                s = "\t\t" + instance.verbalise
                if (single_roles.size > 0)
                  role_values = 
                    single_roles.map{|role|
                        [ role_name = role.to_s.camelcase(true),
                          value = instance.send(role)]
                      }.select{|role_name, value|
                        value
                      }.map{|role_name, value|
                        "#{role_name} = #{value ? value.verbalise : "nil"}"
                      }
                  s += " where " + role_values*", " if role_values.size > 0
                end
                s
              } * "\n"
        }.compact*"\n"
    end
  end
end
