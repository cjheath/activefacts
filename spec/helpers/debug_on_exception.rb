if ENV["RSPEC_DEBUG_ON_EXCEPTION"]
  require 'ruby-debug'; Debugger.start

  class Exception
    alias_method :old_initialize, :initialize

    def initialize *args, &b
      send(:old_initialize, *args, &b)

      if (e = ENV["RSPEC_DEBUG_ON_EXCEPTION"]).index('all') or
	e.index(self.class.name.sub(/.*::/,''))
	puts "Stopped due to #{self.class} at "+caller*"\n\t"
	debugger
	true
      end
    end
  end
end
