require 'rubygems'
require 'activefacts'
require 'activefacts/builder'
require 'activefacts/dump'
include ActiveFacts

administration = Model.Builder "Orienteering" do
    entity :Club do
	value :Code, :nchar, 12, :primary, "has/is of"
	value "is called/is name of", :ClubName, :nvarchar, 128, :unique
	binary "runs/is run by", :Event do
	    unique "EventIsRunByOneClub", :Club	# Only one club runs each Event
	    mandatory :Club
	end
    end

    entity :Map do
	value :MapName, :nvarchar, 80 do
	    primary	# Equivalent to unique, mandatory and preferred
	end
	value :Accessibility, :nchar, 1 do
	    restrict 'A'..'D'
	end
	binary "is owned by/owns", :Club
	binary "is map for/uses", :Event do
	    unique "EventIsOnOneMap", :Map
	    mandatory :Event
	end
    end

    entity :Event do
	value :ID, :autoinc, :primary
	ternary "EventIsNumberIsSeries", :Series, :Number do
	    unique "SeriesNumberIsOfOneEvent", :Series, :Number
	    frequency :should, :Series, 2 # Every Series should have at least two events
	end
	value :EventName, :nvarchar, 50, "is called/is name of" do
	    # EventName is optional, because that's the default.
#!!! REVISIT
	    # unique	    # Every EventName is of one event
	end

	# Every event must either be in a series or have a name, or both
	mandatory :EventName, :EventIsNumberInSeries

	value "starts at", :StartLocation, :nvarchar, 200, :mandatory
	value "starts at", :StartTime, :datetime, :mandatory
    end

    value :Course, :nchar, 2 do
	restrict 'A'..'F', 'PW'
    end

#!!! REVISIT
#    entity :EventCourse do
#	nests binary("offers/is available at", :Event, :Course)
#	unique "EventIncludesEachCourseOnce", :Event, :Course
#	value :IsIndividual, :boolean
#	value :ScoringMethod, :nvarchar, 20 do
#	    restrict 'Score', 'Scatter', 'Special'
#	end
#    end
end

puts "Finished processing #{administration.name}, dumping"
puts "="*70

administration.dump
