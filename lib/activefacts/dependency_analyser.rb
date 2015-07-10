module ActiveFacts
  class DependencyAnalyser
    def initialize enumerable, &block
      @enumerable = enumerable
      analyse_precursors &block
    end

    def analyse_precursors &block
      @precursors = {}
      @enumerable.each do |item|
	@precursors[item] = block.call(item)
      end
    end

    def analyse_precursors_transitive
      all_precursors = proc do |item|
	  p = @precursors[item]
	  all =
	    p + p.map do |precursor|
	      p.include?(precursor) ? [] : all_precursors.call(precursor)
	    end.flatten
	  all.uniq
	end

      @precursors_transitive = {}
      @enumerable.each do |item|
	@precursors_transitive[item] = all_precursors.call(item)
      end
    end

    def analyse_followers
      @followers = Hash.new{|h, k| h[k] = [] }
      @enumerable.each do |item|
	@precursors[item].each do |precursor|
	  @followers[precursor] << item
	end
      end
    end

    def analyse_chasers
      analyse_precursors_transitive unless @precursors_transitive
      analyse_followers unless @followers

      # A follower is an object with us as a precursor, that has no new precursors of its own
      @chasers = {}
      @enumerable.each do |item|
	@chasers[item] =
	  @enumerable.select do |follower|
	    @precursors[follower].include?(item) and
	    (@precursors_transitive[follower] - @precursors_transitive[item] - [item]).size == 0
	  end
      end
    end

    def tsort &block
      analyse_precursors unless @precursors
      emitted = {}
      pass = 0
      until emitted.size == @enumerable.size
	next_items = []
	blocked =
	  @enumerable.inject({}) do |hash, item|
	    next hash if emitted[item]
	    blockers = item.precursors.select{|precursor| !emitted[precursor]}
	    if blockers.size > 0
	      hash[item] = blockers
	    else
	      next_items << item
	    end
	    hash
	  end
	return blocked if next_items.size == 0	# Cannot make progress
	# puts "PASS #{pass += 1}"
	next_items.each do |item|
	  block.call(item)
	  emitted[item] = true
	end
      end
      nil
    end

    def each &b
      if block_given?
	@enumerable.each { |item| yield item}
      else
	@enumerable
      end
    end

    def precursors item = nil, &b
      analyse_precursors unless @precursors
      if item
	if block_given?
	  Array(@precursors[item]).each { |precursor| yield precursor, item }
	else
	  Array(@precursors[item])
	end
      else
	@enumerable.each do |item|
	  precursors(item, &b)
	end
      end
    end

    def precursors_transitive item, &b
      analyse_precursors_transitive unless @precursors_transitive
      if item
	if block_given?
	  Array(@precursors_transitive[item]).each { |precursor| yield precursor, item }
	else
	  Array(@precursors_transitive[item])
	end
      else
	@enumerable.each do |item|
	  precursors_transitive(item, &b)
	end
      end
    end

    def followers item = nil, &b
      analyse_followers unless @followers
      if item
	if block_given?
	  Array(@followers[item]).each { |follower| yield follower, item }
	else
	  Array(@followers[item])
	end
      else
	@enumerable.each do |item|
	  followers(item, &b)
	end
      end
    end

    def chasers item, &b
      analyse_chasers unless @chasers
      if item
	if block_given?
	  Array(@chasers[item]).each { |follower| yield follower, item }
	else
	  Array(@chasers[item])
	end
      else
	@enumerable.each do |item|
	  follower(item, &b)
	end
      end
    end

    # Compute the page rank of the objects
    # If used, the block shold return the starting weight
    def page_rank damping = 0.85, &weight
      weight ||= proc {|item| 1.0}

      @total = 0
      @rank = {}
      @enumerable.each do |item|
	@total += 
	  (@rank[item] = weight.call(item) * 1.0)
      end
      # Normalize:
      @enumerable.each do |item|
	@rank[item] /= @total
      end

      50.times do |iteration|
	@enumerable.each do |item|
	  links = (precursors(item) + followers(item)).uniq
	  linked_rank = links.map do |l|
	      onward_links = (precursors(l) + followers(l)).uniq || @enumerable.size
	      @rank[l] / onward_links.size
	    end.inject(&:+) || 0
	  @rank[item] = (1.0-damping) + damping*linked_rank
	end
      end

      @rank
    end

  end
end

