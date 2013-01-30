if ENV["RSPEC_CTRLC_DEBUG"]
  require 'ruby-debug'; Debugger.start
  trap "INT" do
    puts caller*"\n\t"
    debugger
  end
end
