#       Compile a CQL string into an ActiveFacts vocabulary.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#

module ActiveFacts
  module CQL
    class Compiler < ActiveFacts::CQL::Parser
      def value_type(name, base_type_name, parameters, unit, ranges, mapping_pragmas, enforcement)
        length, scale = *parameters

        # Create the base type:
        base_type = nil
        if (base_type_name != name)
          unless base_type = @constellation.ValueType[[@vocabulary.identifying_role_values, @constellation.Name(base_type_name)]]
            #puts "REVISIT: Creating base ValueType #{base_type_name} in #{@vocabulary.inspect}"
            base_type = @constellation.ValueType(@vocabulary, base_type_name)
            return if base_type_name == name
          end
        end

        # Create and initialise the ValueType:
        vt = @constellation.ValueType(@vocabulary, name)
        vt.supertype = base_type if base_type
        vt.length = length if length
        vt.scale = scale if scale

        # REVISIT: Find and apply the units

        if ranges.size != 0
          vt.value_restriction = value_restriction(ranges, enforcement)
        end
      end

      def unit params
        singular = params[:singular]
        plural = params[:plural]
        base_units = params[:base]
        denominator = params[:coefficient][:denominator]
        numerator = params[:coefficient][:numerator]
        offset = params[:offset]
        approximately = params[:approximately]
        ephemeral = params[:ephemeral]

        if (numerator.to_f / denominator.to_i != 1.0)
          coefficient = @constellation.Coefficient(
              :numerator => numerator.to_f,
              :denominator => denominator.to_i,
              :is_precise => !approximately
            )
        else
          coefficient = nil
        end
        offset = offset.to_f
        offset = nil if offset == 0
        debug :units, "Defining new unit #{singular}#{plural ? "/"+plural : ""}" do
          debug :units, "Coefficient is #{coefficient.numerator}#{coefficient.denominator != 1 ? "/#{coefficient.denominator}" : ""} #{coefficient.is_precise ? "exactly" : "approximately"}" if coefficient
          debug :units, "Offset is #{offset}" if offset
          raise "Redefinition of unit #{singular}" if @constellation.Unit.values.detect{|u| u.name == singular}
          raise "Redefinition of unit #{plural}" if @constellation.Unit.values.detect{|u| u.name == plural}
          unit = @constellation.Unit(:new,
              :name => singular,
              # :plural => plural,
              :coefficient => coefficient,
              :offset => offset,
              :is_fundamental => base_units.empty?,
              :is_ephemeral => ephemeral,
              :vocabulary => @vocabulary
            )
          base_units.each do |base_unit, exponent|
            base = @constellation.Unit.values.detect{|u| u.name == base_unit}
            debug :units, "Base unit #{base_unit}^#{exponent} #{base ? "" : "(implicitly fundamental)"}"
            base ||= @constellation.Unit(:new, :name => base_unit, :is_fundamental => true, :vocabulary => @vocabulary)
            @constellation.Derivation(:derived_unit => unit, :base_unit => base, :exponent => exponent)
          end
          if plural
            plural_unit = @constellation.Unit(:new,
                :name => plural,
                :is_fundamental => false,
                :vocabulary => @vocabulary
              )
            @constellation.Derivation(:derived_unit => plural_unit, :base_unit => unit, :exponent => 1)
          end
        end
      end

    end
  end
end
