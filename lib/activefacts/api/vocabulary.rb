module ActiveFacts
  module Vocabulary
    def concept(name = nil)
      @concept ||= {}
      return @concept unless name
      camel = name.to_s.camelcase(true)
      if (c = @concept[camel])
	return c
      end
      begin
	return const_get(camel)
      rescue
	return nil
      end
    end

    def __delay(concept_sym, args, &block)
      puts "Arranging for delayed binding on #{concept_sym}"
      @delayed ||= Hash.new { |h,k| h[k] = [] }
      @delayed[concept_sym] << [args, block]
    end
  end
end
