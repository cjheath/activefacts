#
#       ActiveFacts Generators.
#       Generate metamodel topic hierarchy (topologically sorted) for a compiled vocabulary
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
require 'activefacts/dependency_analyser'
require 'activefacts/persistence'

module ActiveFacts
  module Generate
    # Generate a topic hierarchy of the metamodel constellation created for an ActiveFacts vocabulary.
    # Invoke as
    #   afgen --topics <file>.cql
    class Topics
    private
      def initialize(vocabulary)
        @vocabulary = vocabulary
        @vocabulary = @vocabulary.Vocabulary.values[0] if ActiveFacts::API::Constellation === @vocabulary
      end

    public
      def generate(out = $>)
	constellation = @vocabulary.constellation

	concepts = constellation.Concept.values.select do |c|
	  !c.embodied_as.is_a?(ActiveFacts::Metamodel::Role) &&
	  !c.implication_rule
	end

	@dep_an = ActiveFacts::DependencyAnalyser.new(concepts) {|c| c.precursors }

=begin
	puts "Concepts are"
	@dep_an.each do |concept|
	  puts "\t#{concept.describe}"
	end
	puts

	puts "Precursors are"
	@dep_an.each do |concept|
	  next unless (p = @dep_an.precursors(concept)).size > 0
	  puts "#{concept.describe}:"
	  p.each do |precursor|
	    puts "\t#{precursor.describe}"
	  end
	end

	puts "Followers are:"
	@dep_an.each do |concept|
	  next unless (f = @dep_an.followers(concept)).size > 0
	  puts "#{concept.describe}:"
	  f.each do |follower|
	    puts "\t#{follower.describe}"
	  end
	end

	puts "Chasers are:"
	@dep_an.each do |concept|
	  next unless (f = @dep_an.chasers(concept)).size > 0
	  puts "#{concept.describe}:"
	  f.each do |follower|
	    puts "\t#{follower.describe}"
	  end
	end
=end

=begin
	puts "Ranks are:"
	page_rank = @dep_an.page_rank
	page_rank.keys.sort_by{|k| -page_rank[k]}.each do |concept|
	  puts("%8.4f\t%s" % [page_rank[concept], concept.describe])
	end
=end

	puts "=== Listed in Ranking Order with chasers ==="
	# List the highest-ranked items that have no un-listed precursors.
	# After each listed item, list the chasers *transitively* before
	# choosing the next highest ranked item.
	@listed = {}
	@page_rank = @dep_an.page_rank    # Get the page_rank
	@page_rank = @page_rank
	@ranked = @page_rank.keys.sort_by{|k| -@page_rank[k]} # Sort decreasing
	until @listed.size >= @ranked.size
	  vt = nil
	  chosen = @ranked.detect do |concept|
	    next if @listed[concept]
	    unlisted_precursors = precursors(concept).
	      reject do |precursor|
		precursor == concept or
		  @listed[precursor] or
		  is_value_type_concept(precursor)
	      end
	    next if unlisted_precursors.size > 0	  # Still has precursors
	    vt ||= concept
	    next if is_value_type_concept(concept)
	    concept
	  end

	  chosen ||= vt	  # Choose a value type if there's no other

	  @cluster = []

	  descend chosen

	  cluster_ranks = @cluster.sort_by{|c| -@page_rank[c]}
	  head = cluster_ranks.detect{|c| c.object_type} || cluster_ranks.first
	  puts "/*\n * #{head.object_type ? head.object_type.name : head.describe}\n */"
	  @cluster.each do |concept|
	    puts concept.describe
	  end
	  puts	  # Put a line between sections
	end

      end

      def is_value_type_concept concept
	o = concept.object_type and o.is_a?(ActiveFacts::Metamodel::ValueType)
      end

      def precursors(concept)
	@dep_an.precursors_transitive(concept).reject{|c| is_value_type_concept(c) }
      end

      # Descend the concept, also the items that are necessarily dumped with concept, so we don't select them again
      def descend(concept, tab = '')
	(@causation ||= [])
	return if @listed[concept] || @causation.include?(concept)  # Recursion prevention
	begin
	  @causation << concept	# Reversed by tge "ensure" below.

	  @dep_an.precursors(concept).each do |precursor|
	    descend(precursor, tab) unless @listed[precursor] || precursor == concept
	  end

	  #puts tab+concept.describe
	  @listed[concept] = true
	  @cluster << concept

	  body = concept.embodied_as
	  case body
	  when ActiveFacts::Metamodel::FactType
	    body.internal_presence_constraints.each do |pc|
	      # puts "Listing #{pc.concept.describe} as internal_presence_constraint of #{concept.describe}"
	      descend(pc.concept, tab+"\t")
	    end
	    if body.entity_type
	      # puts "Listing #{body.entity_type.concept.describe} as objectification of #{concept.describe}"
	      descend(body.entity_type.concept, tab+"\t")
	    end
	    body.all_role.each do |role|
	      role.all_ring_constraint.each do |rc|
		# puts "Listing #{rc.concept.describe} as ring_constraint of #{concept.describe}"
		descend(rc.concept, tab+"\t")
	      end
	    end
	  when ActiveFacts::Metamodel::EntityType
	    body.preferred_identifier.role_sequence.all_role_ref.each do |rr|
	      # puts "Listing #{rr.role.fact_type.concept.describe} as existential fact of #{concept.describe}"
	      descend(rr.role.fact_type.concept, tab+"\t")
	    end
	    descend(body.preferred_identifier.concept, tab+"\t")
	  when ActiveFacts::Metamodel::ValueType
	    if body.value_constraint
	      # puts "Listing #{body.value_constraint.concept.describe} as value constraint of #{concept.describe}"
	      descend(body.value_constraint.concept, tab+"\t")
	    end
	  end

	  # Follow up with unlisted chasers (that have no remaining precursors) in order of decreasing importance:
	  chasers =
	    @dep_an.followers(concept).reject do |follower|
	      @listed[follower] or
		is_value_type_concept(follower) or
		@dep_an.precursors(follower).detect{|p| !@listed[p] && !is_value_type_concept(p) } or
		# Exclude subtypes of entity types from the followers:
		concept.object_type && concept.object_type.is_a?(ActiveFacts::Metamodel::EntityType) && concept.object_type.subtypes.include?(follower.object_type)
	    end.
	    sort_by{|nc| -@page_rank[nc]}

	  chasers.each do |chaser|
	    # puts "**** Listing #{chaser.describe} as chaser of #{concept.describe}"
	    descend(chaser, tab)
	  end

	ensure
	  @causation.pop
	end
      end

    end
  end
end

ActiveFacts::Registry.generator('topics', ActiveFacts::Generate::Topics)
