module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser

      class Unit < Definition
        def initialize singular, plural, numerator, denominator, offset, base_units, approximately, ephemera_url
          @singular = singular
          @plural = plural
          @numerator, @denominator = numerator, denominator
          @offset = offset
          @base_units = base_units  # An array of pairs, each [unit_name, power]
          @approximately = approximately
          @ephemera_url = ephemera_url
        end

        def compile
          if (@numerator.to_f / @denominator.to_i != 1.0)
            coefficient = @constellation.Coefficient(
                @numerator,
                @denominator.to_i,
                !@approximately
                # REVISIT: Activefacts-api is complaining at present. The following is better and should work:
                # :numerator => @numerator,
                # :denominator => @denominator.to_i,
                # :is_precise => !@approximately
              )
          else
            coefficient = nil
          end
          @offset = nil if @offset.to_f == 0

          debug :units, "Defining new unit #{@singular}#{@plural ? "/"+@plural : ""}" do
            debug :units, "Coefficient is #{coefficient.numerator}#{coefficient.denominator != 1 ? "/#{coefficient.denominator}" : ""} #{coefficient.is_precise ? "exactly" : "approximately"}" if coefficient
            debug :units, "Offset is #{@offset}" if @offset
            raise "Redefinition of unit #{@singular}" if @constellation.Unit.values.detect{|u| u.name == @singular}
            raise "Redefinition of unit #{@plural}" if @constellation.Unit.values.detect{|u| u.name == @plural}
            unit = @constellation.Unit(:new,
                :name => @singular,
                :plural_name => @plural,
                :coefficient => coefficient,
                :offset => @offset,
                :is_fundamental => @base_units.empty?,
                :ephemera_url => @ephemera_url,
                :vocabulary => @vocabulary
              )
            @base_units.each do |base_unit, exponent|
              base = @constellation.Unit.values.detect{|u| u.name == base_unit || u.plural_name == base_unit }
              debug :units, "Base unit #{base_unit}^#{exponent} #{base ? "" : "(implicitly fundamental)"}"
              base ||= @constellation.Unit(:new, :name => base_unit, :is_fundamental => true, :vocabulary => @vocabulary)
              @constellation.Derivation(:derived_unit => unit, :base_unit => base, :exponent => exponent)
            end
=begin
            if @plural
              plural_unit = @constellation.Unit(:new,
                  :name => @plural,
                  :is_fundamental => false,
                  :vocabulary => @vocabulary
                )
              @constellation.Derivation(:derived_unit => plural_unit, :base_unit => unit, :exponent => 1)
            end
=end
            unit
          end
        end

        def inspect
          to_s
        end

        def to_s
          super + "Unit(#{
            @singular
          }#{
            @plural ? '/'+@plural : ''
          }) is #{
            @numerator
          }/#{
            @denominator
          }+#{
            @offset
          } #{
            @base_units.map{|b,e|
              b+'^'+e.to_s
            }*'*'
          }"
        end
      end

      class ValueType < ObjectType
        def initialize name, base, parameters, unit, value_constraint, pragmas
          super name
          @base_type_name = base
          @parameters = parameters
          @unit = unit
          @value_constraint = value_constraint
          @pragmas = pragmas
        end

        def compile
          length, scale = *@parameters

          # Create the base type:
          base_type = nil
          if (@base_type_name != @name)
            unless base_type = @constellation.ValueType[[@vocabulary.identifying_role_values, @constellation.Name(@base_type_name)]]
              base_type = @constellation.ValueType(@vocabulary, @base_type_name, :guid => :new)
              return base_type if @base_type_name == @name
            end
          end

          # Create and initialise the ValueType:
          vt = @constellation.ValueType(@vocabulary, @name, :guid => :new)
          vt.is_independent = true if (@pragmas.include? 'independent')
          vt.supertype = base_type if base_type
          vt.length = length if length
          vt.scale = scale if scale

          unless @unit.empty?
            unit_name, exponent = *@unit[0]
            unit = @constellation.Name[unit_name].unit ||
              @constellation.Name[unit_name].unit_as_plural_name
            raise "Unit #{unit_name} for value type #{@name} is not defined" unless unit
            if exponent != 1
              base_unit = unit
              unit_name = base_unit.name+"^#{exponent}"
              unless unit = @constellation.Unit.detect{|k,v| v.name == unit_name } 
                # Define a derived unit (these are skipped on output)
                unit = @constellation.Unit(:new,
                      :vocabulary => @vocabulary,
                      :name => unit_name,
                      :is_fundamental => false
                    )
                @constellation.Derivation(unit, base_unit).exponent = exponent
              end
            end
            vt.unit = unit
          end

          if @value_constraint
            @value_constraint.constellation = @constellation
            vt.value_constraint = @value_constraint.compile
          end

          vt
        end

        def to_s
          "ValueType: #{super} is written as #{
              @base_type_name
            }#{
              @parameters.size > 0 ? "(#{ @parameters.map{|p|p.to_s}*', ' })" : ''
            }#{
              @unit && @unit.length > 0 ? " in #{@unit.inspect}" : ''
            }#{
              @value_constraint ? " "+@value_constraint.to_s : ''
            }#{
              @pragmas.size > 0 ? ", pragmas [#{@pragmas*','}]" : ''
            };"
        end
      end
    end
  end
end
