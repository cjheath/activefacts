module ActiveFacts
  module Generate
    module Rails
      module Helpers
	def rails_plural_name name
	  # Crunch spaces and pluralise the first part, all in snake_case
	  name.pop if name.is_a?(Array) and name.last == []
	  name = name[0]*'_' if name.is_a?(Array) and name.size == 1
	  if name.is_a?(Array)
	    name = ActiveSupport::Inflector.tableize((name[0]*'_').gsub(/\s+/, '_')) +
	      '_' +
	      ActiveSupport::Inflector.underscore((name[1..-1].flatten*'_').gsub(/\s+/, '_'))
	  else
	    ActiveSupport::Inflector.tableize(name.gsub(/\s+/, '_'))
	  end
	end

	def rails_singular_name name
	  # Crunch spaces and convert to snake_case
	  name = name.flatten*'_' if name.is_a?(Array)
	  ActiveSupport::Inflector.underscore(name.gsub(/\s+/, '_'))
	end

	def rails_class_name name
	  name = name*'_' if name.is_a?(Array)
	  ActiveSupport::Inflector.camelize(name.gsub(/\s+/, '_'))
	end

      end
    end
  end

  module Metamodel
    class ObjectType
    end
  end

  module Persistence
    class ForeignKey
      include Generate::Rails::Helpers

      def rails_from_association_name
	rails_singular_name(to_name.join('_'))
      end

      def rails_to_association
	jump = jump_reference
	if jump.is_one_to_one
	  [ "has_one", rails_singular_name(from_name)]
	else
	  [ "has_many", rails_plural_name(from_name)]
	end
      end

    end
  end
end
