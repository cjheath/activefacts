require 'rubygems'
require 'activefacts'

class Units
    class BaseUnit
	attr_reader :unit, :exponent
	def initialize(unit, exponent)
	    @unit = unit
	    @exponent = exponent
	end

	def to_s
	    @unit.to_s + (@exponent != 1 ? "^#{@exponent}" : "")
	end
    end

    class Unit
	attr_reader :coefficient, :is_precise, :baseunits

	def initialize(coefficient, is_precise, baseunits)
	    @coefficient = coefficient
	    @is_precise = is_precise
	    @baseunits = baseunits
	end

	def to_s
	    "#{is_precise ? "=" : "~~"} #{coefficient != 1 ? coefficient.to_s : ""} #{baseunits.map{|b| b.to_s} * " "}"
	end
    end

    def existing(u)
	@units[u] || (u[-1] == ?s && @units[u[0..-2]])
    end

    def initialize(file = '/usr/share/misc/units.lib')
	@prefix = {}
	@units = {}

	File.open(file) { |f|
	    f.each_line { |line|
		# Blow away whole-line comments
		next if line[0] == ?/

		# Blow away inline comments and trailing white space
		line.gsub!(/#.*/, '')
		line.gsub!(/[ 	\015\012]*$/, '')

		# Skip blank lines
		next if line.length == 0

		# Parse off the unit name and the definition:
		/((?:\w|[\$%])*-?)\s+(.*)/.match(line)
		unit = $1
		definition = $2

		next if !unit || unit == ""

		if unit[-1] == ?-
		    # Store the prefixes
		    multiplier = @prefix[definition] || definition.to_f
		    # puts unit[0..-2] + " multiplies by #{multiplier}"
		    @prefix[unit[0..-2]] = multiplier
		    next
		end

		if (definition =~ /\A!/)
		    # Store an empty array for base units
		    @units[unit] = []
		    next
		end
		
		# Split the definition:
		values = definition.split(/(\s|\/|-(?=[^0-9]))+/).delete_if{|w| w == ' ' || w == '-'}

		# Convert numbers in the definitions to numerics:
		coefficient = 1
		is_precise = true
		baseunits = []
		inverse = false
		values.each{|v|
			case v
			when /\A\Z/					# Occurs when you have /unit
			    nil
			when /\A\d+\Z/				# Integer
			    raise "inverse integer" if inverse
			    coefficient = coefficient * v.to_i
			when /\A(\d+)\|(\d+)\Z/			# Rational
			    multiplier = (inverse ? Rational($2.to_i, $1.to_i) : Rational($1.to_i, $2.to_i))
			    coefficient = coefficient * multiplier
			when /\A\.?\d+(:?\.\d+)?(e[-+]?\d+)?\Z/	# Float
			    multiplier = v.to_f
			    coefficient = coefficient *
				(inverse ? 1/multiplier : multiplier)
			when /\A([-+0-9.e]+)\|([-+0-9.e]+)/	# Division of floats
			    multiplier = $1.to_f/$2.to_f
			    coefficient = coefficient * 
				(inverse ? 1/multiplier : multiplier)
			when /\A(['"a-zA-Z_\$%0]*)\^?([1-9][0-9]*)?\Z/	# Named Unit
			    u = $1
			    power = $2 ? $2.to_i : 1
			    base = u
			    unless existing(u)
				longest = 0
				multiplier = 1
				# Search for a prefix:
				@prefix.each_key{|p|
				    if u[0..(p.size-1)] == p and longest < p.size
					longest = p.size
					base = u[p.size..-1]
					multiplier = @prefix[p]
					end
				}
				if longest == 0
				    puts "#{line}: Can't define #{unit} in terms of undefined '#{u}'"
				    next
				end
				unless existing(base)
				    puts "#{line}: Can't define #{unit} in terms of prefixed unit #{u} which is #{multiplier} times undefined #{base}"
				    next
				end

				#puts "found prefixed unit #{u} which is #{base} times #{multiplier}"
				coefficient = coefficient *
				    (inverse ? 1/multiplier : multiplier)
			    end
			    if (base == "fuzz")
				is_precise = false
			    else
				baseunits << BaseUnit.new(base, inverse ? -power : power)
			    end

			when "/"
			    inverse = true				# Following exponents are reversed
			    nil
			else
			    puts line+": "+ v.inspect+", value unmatched in case"
			end
		    }
		@units[unit] = Unit.new(coefficient, is_precise, baseunits)

#		puts "#{unit} #{is_precise ? "=" : "~~"} #{coefficient != 1 ? coefficient.to_s : ""} #{baseunits.map{|b| b.to_s} * " "}"
	    }
	}
    end

    def dump
	@units.keys.sort.each{|unit|
	    puts "#{unit} #{@units[unit]}"
	}
    end

=begin
    # Return a unit made by reducing the passed unit to base units
    def merge(unithash, baseunit)
	unithash[baseunit.unit] ||= 0
	unithash[baseunit.unit] += baseunit.exponent
    end

    def reduce(unit)
	coefficient = unit.coefficient
	baseunits = {}
	unit.baseunits.each{ |base| 
	    if (unit = @units[base.unit])
		unit.
	    else
		merge(baseunits, base)
	    end
	}
    end
=end
end

u = Units.new(ARGV[0])
u.dump
