module ActiveFacts
  module Registry
    def self.generator(name, klass)
      generators[name] = klass
    end

    def self.generators
      @@generators ||= {}
    end
  end
end
