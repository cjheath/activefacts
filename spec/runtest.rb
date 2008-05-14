require 'rubygems'
gem 'rspec', ">= 0.8.0"
require 'spec'

Spec::Runner::CommandLine::run(
        %w{test/activefacts_spec.rb -f s},
        $stderr, $stdout
    )
