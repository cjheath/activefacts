#
#       ActiveFacts Support code.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#

# Return all duplicate objects in the array (using hash-equality)
class Array
  def duplicates(&b)
    inject({}) do |h,e|
      h[e] ||= 0
      h[e] += 1
      h
    end.reject do |k,v|
      v == 1
    end.keys
  end

  if RUBY_VERSION =~ /^1\.8/
    # Fake up Ruby 1.9's Array#index method, mostly
    alias_method :__orig_index, :index
    def index *a, &b
      if a.size == 0
        raise "Not faking Enumerator for #{RUBY_VERSION}" if !b
        (0...size).detect{|i| return i if b.call(self[i]) }
      else
        __orig_index(*a, &b)
      end
    end
  end

  # If any element, or sequence of elements, repeats immediately, delete the repetition.
  # Note that this doesn't remove all re-occurrences of a subsequence, only consecutive ones.
  # The compare_block allows a custom equality comparison.
  def elide_repeated_subsequences &compare_block
    compare_block ||= lambda{|a,b| a == b}
    i = 0
    while i < size  # Need to re-evaluate size on each loop - the array shrinks.
      j = i
      #puts "Looking for repetitions of #{self[i]}@[#{i}]"
      while tail = self[j+1..-1] and k = tail.index {|e| compare_block.call(e, self[i]) }
        length = j+1+k-i
        #puts "Found at #{j+1+k} (subsequence of length #{j+1+k-i}), will need to repeat to #{j+k+length}"
        if j+k+1+length <= size && compare_block[self[i, length], self[j+k+1, length]]
          #puts "Subsequence from #{i}..#{j+k} repeats immediately at #{j+k+1}..#{j+k+length}"
          slice!(j+k+1, length)
          j = i
        else
          j += k+1
        end
      end
      i += 1
    end
    self
  end
end

class String
  class Words
    def initialize words
      @words = words
    end

    def map(&b)
      @words.map(&b)
    end

    def to_s
      titlecase
    end

    def titlewords
      @words.map do |word|
	word[0].upcase+word[1..-1].downcase
      end
    end

    def titlecase
      titlewords.join('')
    end

    def capwords
      @words.map do |word|
	word[0].upcase+word[1..-1]
      end
    end

    def capcase
      capwords.join('')
    end

    def camelwords
      count = 0
      @words.map do |word|
	if (count += 1) == 1
	  word
	else
	  word[0].upcase+word[1..-1].downcase
	end
      end
    end

    def camelcase
      camelwords.join('')
    end

    def snakewords
      @words.map do |w|
	w.downcase
      end
    end

    def snakecase
      snakewords.join('_')
    end

    def to_a
      @words
    end

    def +(words)
      Words.new(@words + Array(words))
    end
  end

  def words
    Words.new(
      self.split(/(?:[^[:alnum:]]+|(?<=[[:alnum:]])(?=[[:upper:]][[:lower:]]))/).reject{|w| w == '' }
    )
  end
end

