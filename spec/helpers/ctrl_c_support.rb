# Monkey patch in CTRL-C support for rspec from 
# http://github.com/dchelimsky/rspec/commit/029f77c5063894cf52af05335b8e1c278411978b
# until it gets released

module Spec
  module Example
    module ExampleMethods
      def execute(run_options, instance_variables) # :nodoc:
        run_options.reporter.example_started(@_proxy)
        set_instance_variables_from_hash(instance_variables)
 
        execution_error = nil
        Timeout.timeout(run_options.timeout) do
          begin
            before_each_example
            instance_eval(&@_implementation)
          rescue Interrupt
            exit 1
          rescue Exception => e
            execution_error ||= e
          end
          begin
            after_each_example
          rescue Interrupt
            exit 1
          rescue Exception => e
            execution_error ||= e
          end
        end
 
        run_options.reporter.example_finished(@_proxy.update(description), execution_error)
        success = execution_error.nil? || ExamplePendingError === execution_error
      end
    end
  end
end

module Spec
  module Runner
    class ExampleGroupRunner
      def run
        prepare
        success = true
        example_groups.each do |example_group|
          success = success & example_group.run(@options)
        end
        finish
        success
      end
    end
  end
end