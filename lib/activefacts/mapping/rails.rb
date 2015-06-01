require 'activefacts/vocabulary'
require 'activefacts/persistence'
require 'active_support'
require 'digest/sha1'

module ActiveFacts
  module Persistence

    def self.rails_plural_name name
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

    def self.rails_singular_name name
      # Crunch spaces and convert to snake_case
      name = name.flatten*'_' if name.is_a?(Array)
      ActiveSupport::Inflector.underscore(name.gsub(/\s+/, '_'))
    end

    class Column
      def rails_name
	Persistence::rails_singular_name(name('_'))
      end

      def rails_type
	type_name, params, constraints = *type()
	rails_type = case type_name
	  when /^Auto ?Counter$/
	    'serial'	    # REVISIT: Need to detect surrogate ID fields and handle them correctly

	  when /^[Ug]uid$/i
	    'uuid'

	  when /^Unsigned ?Integer$/,
	    /^Integer$/,
	    /^Signed ?Integer$/,
	    /^Unsigned ?Small ?Integer$/,
	    /^Signed ?Small ?Integer$/,
	    /^Unsigned ?Tiny ?Integer$/
	    length = nil
	    'integer'

	  when /^Decimal$/
	    'decimal'

	  when /^Fixed ?Length ?Text$/, /^Char$/
	    'string'
	  when /^Variable ?Length ?Text$/, /^String$/
	    'string'
	  when /^Large ?Length ?Text$/, /^Text$/
	    'text'

	  when /^Date ?And ?Time$/, /^Date ?Time$/
	    'datetime'
	  when /^Date$/
	    'datetime'
	  when /^Time$/
	    'time'
	  when /^Auto ?Time ?Stamp$/
	    'timestamp'

	  when /^Money$/
	    'decimal'
	  when /^Picture ?Raw ?Data$/, /^Image$/, /^Variable ?Length ?Raw ?Data$/, /^Blob$/
	    'binary'
	  when /^BIT$/
	    'boolean'
	  else type # raise "ActiveRecord type unknown for standard type #{type}"
	  end
	[rails_type, params[:length]]
      end
    end

    class Index
      def rails_name
	column_names = columns.map{|c| c.rails_name }
	index_name = "index_#{on.rails_name+'_on_'+column_names*'_'}"
	if index_name.length > 63
	  hash = Digest::SHA1.hexdigest index_name
	  index_name = index_name[0, 53] + '__' + hash[0, 8]
	end
	index_name
      end
    end

    class ForeignKey
      def rails_from_association_name
	Persistence::rails_singular_name(to_name.join('_'))
      end

      def rails_to_association
	jump = jump_reference
	if jump.is_one_to_one
	  [ "has_one", Persistence::rails_singular_name(from_name)]
	else
	  [ "has_many", Persistence::rails_plural_name(from_name)]
	end
      end
    end
  end

  module Metamodel
    class ObjectType
      def rails_name
	Persistence::rails_plural_name(name)
      end

      def rails_singular_name
	Persistence::rails_singular_name(name)
      end

      def rails_class_name
	ActiveSupport::Inflector.camelize(name.gsub(/\s+/, '_'))
      end
    end
  end
end
