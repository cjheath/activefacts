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
                :numerator => @numerator,
                :denominator => @denominator.to_i,
                :is_precise => !@approximately
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
      end

      class ValueType < Concept
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
              base_type = @constellation.ValueType(@vocabulary, @base_type_name)
              return base_type if @base_type_name == @name
            end
          end

          # Create and initialise the ValueType:
          vt = @constellation.ValueType(@vocabulary, @name)
          vt.is_independent = true if (@pragmas.include? 'independent')
          vt.supertype = base_type if base_type
          vt.length = length if length
          vt.scale = scale if scale

          raise "REVISIT: ValueType units are recognised but not yet compiled" unless @unit.empty?

          if @value_constraint
            @value_constraint.constellation = @constellation
            vt.value_constraint = @value_constraint.compile
          end

          vt
        end
      end
    end
  end
end
