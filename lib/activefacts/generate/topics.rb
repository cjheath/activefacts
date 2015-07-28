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
	@constellation = @vocabulary.constellation

	@concepts = @constellation.Concept.values.select do |c|
	  !c.embodied_as.is_a?(ActiveFacts::Metamodel::Role) &&
	  !c.implication_rule
	end

	@concept_deps = ActiveFacts::DependencyAnalyser.new(@concepts) {|c| c.precursors }

	# list_concepts(@concept_deps)
	# list_precursors(@concept_deps)
	# list_followers(@concept_deps)
	# list_chasers(@concept_deps)
	# list_ranks(@concept_deps)

#	@constellation.Topic.values.each do |topic|
#	  puts "#{topic.topic_name} depends on #{topic.precursors.map(&:topic_name)*', '}"
#	end

	# analyse_topic_sequence

	list_groups_by_rank @concept_deps

      end

      def list_concepts concept_deps
	puts "Concepts are"
	concept_deps.each do |concept|
	  puts "\t#{concept.describe}"
	end
	puts
      end

      def list_precursors(concept_deps)
	puts "Precursors are"
	concept_deps.each do |concept|
	  next unless (p = concept_deps.precursors(concept)).size > 0
	  puts "#{concept.describe}:"
	  p.each do |precursor|
	    puts "\t#{precursor.describe}"
	  end
	end
      end

      def list_followers(concept_deps)
	puts "Followers are:"
	concept_deps.each do |concept|
	  next unless (f = concept_deps.followers(concept)).size > 0
	  puts "#{concept.describe}:"
	  f.each do |follower|
	    puts "\t#{follower.describe}"
	  end
	end
      end

      def list_chasers(concept_deps)
	puts "Chasers are:"
	concept_deps.each do |concept|
	  next unless (f = concept_deps.chasers(concept)).size > 0
	  puts "#{concept.describe}:"
	  f.each do |follower|
	    puts "\t#{follower.describe}"
	  end
	end
      end

      def list_ranks(concept_deps)
	puts "Ranks are:"
	page_rank = concept_deps.page_rank
	page_rank.keys.sort_by{|k| -page_rank[k]}.each do |concept|
	  puts("%8.4f\t%s" % [page_rank[concept], concept.describe])
	end
      end

      def analyse_topic_sequence
	if @constellation.Topic.size == 1
	  @topics = @constellation.Topic.values.first
	else
	  puts "=== Analysing existing topics ==="
	  @topic_analyser = ActiveFacts::DependencyAnalyser.new(@constellation.Topic.values) do |topic|
	    topic.precursors
	  end

	  @topics = []
	  failed_topics = @topic_analyser.tsort { |topic|
	    @topics << topic
	    puts "#{topic.topic_name} including #{topic.all_concept.size} concepts"
	  }
	  if failed_topics
	    puts "Topological sort of topics is impossible"

	    # REVISIT: The strategy here should be to look at the structure of the dependency loop
	    # involving the highest-rank topic. Choose the loop member that has fewest dependencies
	    # involving individual concepts, and dump that (it will need to flip topic to dump
	    # those dependencies). That should break the loop in a minimal way, so we can continue.

	    failed_topics.each do |topic, precursor_topics|
	      puts "#{topic.topic_name} depends on:"
	      precursor_topics.each do |precursor_topic|
		puts "\t#{precursor_topic.topic_name} because of:"

		blocking_concept =
		  precursor_topic.all_concept.select{|concept| 
		    concept.precursors.detect{|cp|
		      cp.topic == precursor_topic
		    }
		  }

		  blocking_concept.each do |concept|
		    puts "\t\t#{concept.describe} (depends on #{concept.precursors.map(&:topic).uniq.map(&:topic_name).sort.inspect})"
		  end
	      end
	    end
	    return
	  end
	end
      end

      def list_groups_by_rank concept_deps
	puts "=== Concepts listed in Ranking Order with chasers ==="
	# List the highest-ranked items that have no un-listed precursors.
	# After each listed item, list the chasers *transitively* before
	# choosing the next highest ranked item.
	@listed = {}

	start = Time.now
	@page_rank = concept_deps.page_rank    # Get the page_rank
	# puts "done in #{Time.now-start}"

	@ranked = @page_rank.keys.sort_by{|k| -@page_rank[k]} # Sort decreasing
	@topic = nil
	until @listed.size >= @ranked.size
	  vt = nil  # Capture the first listable ValueType, which we'll choose if we must
	  chosen = @ranked.detect do |concept|
	    next if @listed[concept]

	    unlisted_precursors = 
	      concept_deps.precursors_transitive(concept).
	      reject do |precursor|
		is_value_type_concept(precursor) or
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

	  descend concept_deps, chosen

	  cluster_ranks = @cluster.sort_by{|c| -@page_rank[c]}
	  head = cluster_ranks.detect{|c| c.object_type} || cluster_ranks.first
	  puts "/*\n * #{head.object_type ? head.object_type.name : head.describe}\n */"
	  @cluster.each do |concept|
	    puts '*'*10+" TOPIC #{@topic = concept.topic.topic_name}" if @topic != concept.topic.topic_name
	    puts concept.describe
	  end
	  puts	  # Put a line between sections
	end
      end

      # Descend the concept, also the items that are necessarily dumped with concept, so we don't select them again
      def descend(concept_deps, concept, tab = '')
	@causation ||= []
	@cluster ||= []
	return if @listed[concept] || @causation.include?(concept)  # Recursion prevention
	begin
	  @causation << concept	# Reversed by the "ensure" below.

	  concept_deps.precursors(concept).each do |precursor|
	    descend(concept_deps, precursor, tab) unless @listed[precursor] || precursor == concept
	  end

	  #puts tab+concept.describe
	  @listed[concept] = true
	  @cluster << concept

	  body = concept.embodied_as
	  case body
	  when ActiveFacts::Metamodel::FactType
	    body.internal_presence_constraints.each do |pc|
	      # puts "Listing #{pc.concept.describe} as internal_presence_constraint of #{concept.describe}"
	      descend(concept_deps, pc.concept, tab+"\t")
	    end
	    if body.entity_type
	      # puts "Listing #{body.entity_type.concept.describe} as objectification of #{concept.describe}"
	      descend(concept_deps, body.entity_type.concept, tab+"\t")
	    end
	    body.all_role.each do |role|
	      role.all_ring_constraint.each do |rc|
		# puts "Listing #{rc.concept.describe} as ring_constraint of #{concept.describe}"
		descend(concept_deps, rc.concept, tab+"\t")
	      end
	    end
	  when ActiveFacts::Metamodel::EntityType
	    body.preferred_identifier.role_sequence.all_role_ref.each do |rr|
	      # puts "Listing #{rr.role.fact_type.concept.describe} as existential fact of #{concept.describe}"
	      descend(concept_deps, rr.role.fact_type.concept, tab+"\t")
	    end
	    descend(concept_deps, body.preferred_identifier.concept, tab+"\t")
	  when ActiveFacts::Metamodel::ValueType
	    if body.value_constraint
	      # puts "Listing #{body.value_constraint.concept.describe} as value constraint of #{concept.describe}"
	      descend(concept_deps, body.value_constraint.concept, tab+"\t")
	    end
	  end

	  # Follow up with unlisted chasers (that have no remaining precursors) in order of decreasing importance:
	  chasers =
	    concept_deps.followers(concept).reject do |follower|
	      @listed[follower] or
		is_value_type_concept(follower) or
		concept_deps.precursors(follower).detect{|p| !@listed[p] && !is_value_type_concept(p) } or
		# Exclude subtypes of entity types from the followers:
		concept.object_type && concept.object_type.is_a?(ActiveFacts::Metamodel::EntityType) && concept.object_type.subtypes.include?(follower.object_type)
	    end.
	    sort_by{|nc| -@page_rank[nc]}

	  chasers.each do |chaser|
	    # puts "**** Listing #{chaser.describe} as chaser of #{concept.describe}"
	    descend(concept_deps, chaser, tab)
	  end

	ensure
	  @causation.pop
	end
      end

      def is_value_type_concept concept
	o = concept.object_type and o.is_a?(ActiveFacts::Metamodel::ValueType)
      end

    end
  end
end

ActiveFacts::Registry.generator('topics', ActiveFacts::Generate::Topics)
